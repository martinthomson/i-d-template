#!/usr/bin/env python3

import os
import sys
import json
import requests
import argparse
from datetime import datetime, timezone
import time
import re
import dateutil.parser as dp
import shutil
import warnings

parser = argparse.ArgumentParser(description="Archive repo issues and PRs.")
parser.add_argument("repo", help="GitHub repo to archive (e.g. quicwg/base-drafts)")
parser.add_argument("githubToken", help="GitHub OAuth token")
parser.add_argument("outFile", default=None, nargs="?", help="destination for output")
parser.add_argument(
    "--reference oldfile",
    dest="refFile",
    nargs="?",
    help="older file produced by this tool for reference",
)
parser.add_argument(
    "--issues-only",
    dest="issuesOnly",
    default=False,
    action="store_true",
    help="download issues, but not pull requests",
)
parser.add_argument(
    "--quiet",
    dest="quiet",
    default=False,
    action="store_true",
    help="do not output HTTP requests",
)
args = parser.parse_args()

if not args.githubToken and "GH_TOKEN" in os.environ.keys():
    args.githubToken = os.environ["GH_TOKEN"]

if args.repo[-1] == "/":
    args.repo = args.repo[:-1]

API_headers = {
    "user-agent": "martinthomson/i-d-template/archive_repo.py",
    "authorization": "bearer " + args.githubToken,
}

s = requests.Session()
s.headers.update(API_headers)

now = datetime.now(timezone.utc)

#######################
## Query definitions ##
#######################

# Query fragments

gql_LabelFields = """
fragment labels on Labelable {
    labels(first: 5) {
        nodes { name }
    }
}
"""

gql_AssigneeFields = """
fragment assignees on Assignable {
    assignees(first: 5) {
        nodes { login }
    }
}
"""

gql_AuthorFields = """
fragment author on Comment {
    author { login }
    authorAssociation
}
"""

gql_Comment_Fields = """
fragment commentFields on Comment {
    body
    createdAt
    updatedAt
}
"""

gql_RateLimit = """
fragment rateLimit on Query {
    rateLimit {
        remaining
        resetAt
    }
}
"""

gql_Paged = """
pageInfo {
    endCursor
    hasNextPage
}
"""

# Issues

gql_Issue_Fields = (
    """
fragment issueFields on Issue {
    number
    id
    title
    url
    state
    ...author
    ...assignees
    ...labels
    ...commentFields
    closedAt
    comments(first: 100) {
        nodes {
            ...author
            ...commentFields
        }
        """
    + gql_Paged
    + """
    }
}
"""
    + gql_AuthorFields
    + gql_AssigneeFields
    + gql_Comment_Fields
    + gql_LabelFields
)

gql_Issues_Query = (
    "nodes { ...issueFields }"
    + gql_Paged
    + """
    }
  }
  ...rateLimit
}
"""
    + gql_Issue_Fields
    + gql_RateLimit
)

gql_AllIssues_First = (
    """
query($owner: String!, $repo: String!){
  repository(owner: $owner, name: $repo) {
    issues(first: 100) {
"""
    + gql_Issues_Query
)

gql_AllIssues_Subsequent = (
    """
query($owner: String!, $repo: String!, $cursor: String!){
  repository(owner: $owner, name: $repo) {
    issues(first: 100, after: $cursor) {
"""
    + gql_Issues_Query
)

gql_UpdatedIssues_First = (
    """
query($owner: String!, $repo: String!, $filters: IssueFilters){
  repository(owner: $owner, name: $repo) {
    issues(first: 100, filterBy: $filters) {
"""
    + gql_Issues_Query
)

gql_UpdatedIssues_Subsequent = (
    """
query($owner: String!, $repo: String!, $filters: IssueFilters, $cursor: String!){
  repository(owner: $owner, name: $repo) {
    issues(first: 100, filterBy: $filters, after: $cursor) {
"""
    + gql_Issues_Query
)

gql_Issue_Comments_Query = (
    """
query($id: ID!, $cursor: String!){
    node(id: $id) {
        ...on Issue {
            comments(first:100, after:$cursor) {
                nodes {
                    ...author
                    ...commentFields
                }
        """
    + gql_Paged
    + """
            }
        }
    }
    ...rateLimit
}
"""
    + gql_Comment_Fields
    + gql_AuthorFields
    + gql_RateLimit
)

# Pull Requests

gql_Review_Fields = (
    """
fragment reviewFields on PullRequestReview {
    id
    commit { abbreviatedOid }
    ...author
    state
    ...commentFields
    comments(first: 50) {
        nodes {
            originalPosition
            ...commentFields
        }
        """
    + gql_Paged
    + """
    }
}
"""
    + gql_Comment_Fields
    + gql_AuthorFields
)

gql_PullRequest_Fields = (
    """
fragment prFields on PullRequest {
    number
    id
    title
    url
    state
    ...author
    ...assignees
    ...labels
    ...commentFields
    closedAt
    mergedAt
    mergedBy { login }
    comments(first: 100) {
        nodes {
            ...author
            ...commentFields
        }
        """
    + gql_Paged
    + """
    }
    reviews(first: 50) {
        nodes {
            ...reviewFields
        }
        """
    + gql_Paged
    + """
    }
}
"""
    + gql_AssigneeFields
    + gql_LabelFields
    + gql_Review_Fields
)
# ...reviewFields definition includes ...commentFields and ...author

gql_PullRequest_Query = (
    "nodes { ...prFields }"
    + gql_Paged
    + """
    }
  }
  ...rateLimit
}
"""
    + gql_PullRequest_Fields
    + gql_RateLimit
)

gql_AllPRs_Initial = (
    """
query($owner: String!, $repo: String!){
  repository(owner: $owner, name: $repo) {
    pullRequests(first: 10, orderBy: {field: UPDATED_AT, direction:DESC}) {
"""
    + gql_PullRequest_Query
)

gql_AllPRs_Subsequent = (
    """
query($owner: String!, $repo: String!, $cursor: String!){
  repository(owner: $owner, name: $repo) {
    pullRequests(first: 25, after: $cursor, orderBy: {field: UPDATED_AT, direction:DESC}) {
"""
    + gql_PullRequest_Query
)

gql_PR_Comments_Query = (
    """
query($id: ID!, $cursor: String!){
    node(id: $id) {
        ...on PullRequest {
            comments(first:100, after:$cursor) {
                nodes { ...commentFields }
        """
    + gql_Paged
    + """
            }
        }
    }
}
"""
    + gql_Comment_Fields
    + gql_RateLimit
)

gql_PR_Review_Query = (
    """
query($id: ID!, $cursor: String!){
    node(id: $id) {
        ...on PullRequest {
            reviews(first:100, after:$cursor) {
                nodes { ...reviewFields }
        """
    + gql_Paged
    + """
            }
        }
    }
    ...rateLimit
}
"""
    + gql_Review_Fields
    + gql_RateLimit
)

gql_PR_ReviewComments_Query = (
    """
query($id: ID!, $cursor: String!){
    node(id: $id) {
        ...on PullRequestReview {
            comments(first: 50, after:$cursor) {
                nodes {
                    originalPosition
                    ...commentFields
                }
        """
    + gql_Paged
    + """
            }
        }
    }
    ...rateLimit
}
"""
    + gql_Comment_Fields
    + gql_RateLimit
)

# Labels

gql_Labels_Query = (
    """
query($owner: String!, $repo: String!){
    repository(owner: $owner, name: $repo) {
        labels(first:100) {
            nodes {
                name
                description
                color
            }
        """
    + gql_Paged
    + """
        }
    }
    ...rateLimit
}
"""
    + gql_RateLimit
)

gql_MoreLabels_Query = (
    """
query($owner: String!, $repo: String!, $cursor: String!){
    repository(owner: $owner, name: $repo) {
        labels(first:100, after:$cursor) {
            nodes {
                name
                description
                color
            }
            """
    + gql_Paged
    + """
        }
    }
    ...rateLimit
}
"""
    + gql_RateLimit
)


##########################
## Function definitions ##
##########################


last_request_limit = 5000


def submit_query(query, variables, display):
    global last_request_limit

    url = "https://api.github.com/graphql"

    bodyjson = {"query": re.sub("\s+", " ", query).strip()}
    if variables:
        bodyjson["variables"] = variables
    body = json.dumps(bodyjson)

    output = f"Submitting query for {display} with "
    output += str(variables) if variables else "no parameters"
    log(output)

    for attempt in range(3):
        try:
            response = s.post(url, body)
            response.raise_for_status()
            break
        except requests.exceptions.HTTPError as e:
            # TODO:  This might not be what rate-limit looks like in GraphQL;
            #   I haven't managed to hit the rate limit yet.
            if (
                e.response.status_code == "403"
                and "x-ratelimit-reset" in e.response.headers.keys()
            ):
                # We're rate-limited; STALL
                reset = int(e.response.headers["x-ratelimit-reset"])
                time_to_sleep = reset - datetime.now().timestamp() + 1
                print(
                    "GitHub API rate-limited; waiting for"
                    + str(time_to_sleep)
                    + "seconds"
                )
                time.sleep(time_to_sleep)
                continue
            else:
                log(e.request.url)
                log(e.request.headers)
                log(e.response.headers)
                eprint(e.response.content)
                if attempt != 2:
                    delay = 10 * (attempt + 1)
                    eprint(f"Retrying ({attempt + 1}) after {delay} seconds...")
                    time.sleep(delay)
                else:
                    raise

    result = response.json()

    if "data" in result.keys() and result["data"] is not None:
        if "rateLimit" in result["data"]:
            last_request_limit = result["data"]["rateLimit"]["remaining"]
            if last_request_limit < 2:
                # We're about to be rate-limited; STALL
                reset = dp.parse(result["data"]["rateLimit"]["resetAt"])
                time_to_sleep = int(reset - datetime.datetime.now()) + 1
                eprint(
                    "GitHub API rate-limited; waiting for "
                    + str(time_to_sleep)
                    + "seconds"
                )
                time.sleep(time_to_sleep)
                last_request_limit = 5000

            del result["data"]["rateLimit"]
        return result["data"]

    raise RuntimeError(result.get("errors", "Empty response"))


def followPagination(node, key, query, display):
    get_more = node[key]["pageInfo"]["hasNextPage"]
    cursor = node[key]["pageInfo"]["endCursor"]
    while get_more:
        # Need to paginate
        query_variables = {"id": node["id"], "cursor": cursor}
        more = submit_query(query, query_variables, display)

        node[key]["nodes"] += more["node"][key]["nodes"]

        get_more = more["node"][key]["pageInfo"]["hasNextPage"]
        cursor = more["node"][key]["pageInfo"]["endCursor"]
    del node[key]["pageInfo"]


def collapse_single(thing, key, name):
    "Collapse something in the form of { x: nodes [ { $name: 'stuff' }] }"
    thing[key] = [item[name] for item in thing[key]["nodes"]]


def collapse(thing, key):
    "Collapse something in the form of { x: nodes [] }"
    thing[key] = thing[key]["nodes"]


def eprint(*str, **kwargs):
    print(*str, file=sys.stderr, **kwargs)


if args.quiet:

    def log(**kwargs):
        pass


else:

    def log(*str, **kwargs):
        eprint(*str, **kwargs)


#####################
## Body of program ##
#####################

## Read in the reference files, if any
issue_ref = dict()
pr_ref = dict()
lastSuccess = None
ref_is_issues_only = True

if args.refFile:
    try:
        with open(args.refFile, "r") as ref_file:
            raw_reference = json.load(ref_file)

            fileIsValid = True
            for element in ("magic", "timestamp", "issues", "repo"):
                if element not in raw_reference:
                    fileIsValid = False
                    break
            if not fileIsValid or raw_reference["magic"] != "B8n2c@e8kvfx":
                warnings.warn("Input file does not appear to be generated by this tool")
                fileIsValid = False

            if fileIsValid and raw_reference["repo"] != args.repo:
                warnings.warn("Input file was generated from a different repo")
                fileIsValid = False

            if fileIsValid:
                lastSuccess = dp.parse(raw_reference["timestamp"])
                issue_ref = dict(
                    [(issue["number"], issue) for issue in raw_reference["issues"]]
                )
                if "pulls" in raw_reference:
                    ref_is_issues_only = False
                    pr_ref = dict([(pr["number"], pr) for pr in raw_reference["pulls"]])
    except:
        warnings.warn("Unable to read input file; proceeding without it")
        pass


## Download from GitHub the full issues list (if no reference) or the updated issues list (if reference)
issue_cursor = None
get_more_issues = True
just_copy_old_file = True if args.refFile else False
(owner, repo) = args.repo.split("/", 1)

while get_more_issues:
    if issue_cursor is None:
        # Initial issue fetch
        query = gql_AllIssues_First
        variables = {"owner": owner, "repo": repo}
        if lastSuccess:
            variables["filters"] = {"since": lastSuccess.isoformat()}
            query = gql_UpdatedIssues_First
    else:
        # Fetching more issues
        query = gql_AllIssues_Subsequent
        variables = {"owner": owner, "repo": repo, "cursor": issue_cursor}
        if lastSuccess:
            variables["filters"] = {"since": lastSuccess.isoformat()}
            query = gql_UpdatedIssues_Subsequent

    data = submit_query(query, variables, "issues")

    # Iterate through the issues
    issues = data["repository"]["issues"]

    for issue in issues["nodes"]:
        number = issue["number"]
        # Are the comments on this issue complete?
        followPagination(
            issue,
            "comments",
            gql_Issue_Comments_Query,
            f"additional comments on issue #{number}",
        )

        # Collapse some nodes
        issue["author"] = issue["author"]["login"]
        collapse_single(issue, "labels", "name")
        collapse_single(issue, "assignees", "login")
        collapse(issue, "comments")
        for comment in issue["comments"]:
            comment["author"] = comment["author"]["login"]

        # Delete the old instance; add this instance
        if number in issue_ref.keys():
            del issue_ref[number]
        issue_ref[number] = issue
        just_copy_old_issues = False

    get_more_issues = issues["pageInfo"]["hasNextPage"]
    issue_cursor = issues["pageInfo"]["endCursor"]

## Similar process with PRs, except they don't have a filter
if not args.issuesOnly:

    issue_cursor = None
    get_more_issues = True

    # Since PRs can't be filtered by their update time, we retrieve
    # them in update-time order and cut off pagination once we're
    # older than the reference file.

    while get_more_issues:
        query = gql_AllPRs_Initial
        variables = {"owner": owner, "repo": repo}
        if issue_cursor is not None:
            query = gql_AllPRs_Subsequent
            variables["cursor"] = issue_cursor

        data = submit_query(query, variables, "pull requests")

        # Iterate through the PRs
        prs = data["repository"]["pullRequests"]

        for pr in prs["nodes"]:
            number = pr["number"]

            # Since we can't filter, check if we already have this one.
            if number in pr_ref:
                ref_updatedAt = dp.parse(pr_ref[number]["updatedAt"])
                dl_updatedAt = dp.parse(pr["updatedAt"])
                if ref_updatedAt >= dl_updatedAt:
                    continue

            # Issues only have comments; PRs have both comments and reviews,
            # and reviews themselves have comments.
            followPagination(
                pr,
                "comments",
                gql_PR_Comments_Query,
                f"additional comments on PR#{number}",
            )
            followPagination(
                pr, "reviews", gql_PR_Review_Query, f"additional reviews on PR#{number}"
            )

            for review in pr["reviews"]["nodes"]:
                followPagination(
                    review,
                    "comments",
                    gql_PR_ReviewComments_Query,
                    f"additional review comments on PR#{number}",
                )

            # Collapse some nodes
            pr["author"] = pr["author"]["login"]
            if pr["mergedBy"] is not None:
                pr["mergedBy"] = pr["mergedBy"]["login"]
            collapse_single(pr, "labels", "name")
            collapse_single(pr, "assignees", "login")
            collapse(pr, "comments")
            for comment in pr["comments"]:
                comment["author"] = comment["author"]["login"]
            collapse(pr, "reviews")
            for review in pr["reviews"]:
                review["author"] = review["author"]["login"]
                collapse(review, "comments")

            # Delete the old instance; add this instance
            if number in pr_ref:
                del pr_ref[number]
            pr_ref[number] = pr
            just_copy_old_file = False

        get_more_issues = prs["pageInfo"]["hasNextPage"]
        issue_cursor = prs["pageInfo"]["endCursor"]

        # Stop paginating if we've caught up to the last download
        if prs["nodes"] and lastSuccess and not ref_is_issues_only:
            oldestRetrieved = dp.parse(prs["nodes"][-1]["updatedAt"])
            if oldestRetrieved < lastSuccess:
                get_more_issues = False

# Fetch the Labels
labels_ref = list()
issue_cursor = None
get_more_issues = True
while get_more_issues:
    query = gql_Labels_Query
    variables = {"owner": owner, "repo": repo}
    if issue_cursor is not None:
        query = gql_MoreLabels_Query
        variables["cursor"] = issue_cursor

    labels = submit_query(query, variables, "labels")
    labels_ref += labels["repository"]["labels"]["nodes"]

    get_more_issues = labels["repository"]["labels"]["pageInfo"]["hasNextPage"]
    issue_cursor = labels["repository"]["labels"]["pageInfo"]["endCursor"]


## Ready to output

## Pick up everything in the reference if nothing new was downloaded
if just_copy_old_file:
    shutil.copyfile(args.refFile, args.outFile)
else:
    output = {
        "magic": "B8n2c@e8kvfx",
        "timestamp": now.isoformat(),
        "repo": args.repo,
        "labels": labels_ref,
        "issues": [issue for (id, issue) in sorted(issue_ref.items())],
    }
    if not args.issuesOnly:
        output["pulls"] = [pr for (id, pr) in sorted(pr_ref.items())]

    if args.outFile:
        with open(args.outFile, "w") as output_file:
            json.dump(output, output_file, indent=2)
    else:
        json.dump(output, sys.stdout, indent=2)

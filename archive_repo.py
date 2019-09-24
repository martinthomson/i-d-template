#!/usr/bin/env python3

import os
import sys
import json
import requests
import argparse
import datetime
import time
import re
import dateutil.parser as dp
import shutil

parser = argparse.ArgumentParser(description="Archive repo issues and PRs.")
parser.add_argument("repo", help="GitHub repo to archive (e.g. quicwg/base-drafts)")
parser.add_argument(
    "outIssues",
    default="issues.json",
    nargs="?",
    help="destination for issues (default: issues.json)",
)
parser.add_argument(
    "outPullRequests",
    default="pulls.json",
    nargs="?",
    help="destination for pull requests (default: pulls.json)",
)
parser.add_argument(
    "-ri",
    dest="refIssues",
    nargs="?",
    help="older issues file produced by this tool for reference",
)
parser.add_argument(
    "-rp",
    dest="refPullRequests",
    nargs="?",
    help="older pull request file produced by this tool for reference",
)
parser.add_argument(
    "-date",
    dest="lastSuccessDateTime",
    nargs="?",
    help="optional date/time reference files were successfully produced; erring earlier is fine, but later will drop data",
)
parser.add_argument(
    "--issues-only",
    dest="issuesOnly",
    default=False,
    action="store_true",
    help="download issues, but not pull requests",
)
parser.add_argument(
    "--remove-prs-from-issues",
    dest="filterPRs",
    default=False,
    action="store_true",
    help="remove PRs from issues file",
)
parser.add_argument(
    "--quiet",
    dest="quiet",
    default=False,
    action="store_true",
    help="do not output HTTP requests",
)
parser.add_argument(
    "--omit-old",
    dest="omitOld",
    default=False,
    action="store_true",
    help="do not copy unchanged items from old file to new file",
)
parser.add_argument(
    "-token", dest="githubToken", default=None, help="GitHub OAuth token"
)
args = parser.parse_args()

if args.lastSuccessDateTime and not args.omitOld and not args.refIssues:
    raise ValueError("If date is specified, old issues file must be provided")

if not args.githubToken and "GH_TOKEN" in os.environ.keys():
    args.githubToken = os.environ["GH_TOKEN"]

if args.repo[-1] == "/":
    args.repo = args.repo[:-1]

API_headers = {"user-agent": "MikeBishop"}

if args.githubToken:
    API_headers["authorization"] = "token " + args.githubToken
else:
    print("No OAuth token -- odds of rate-limiting are high")

s = requests.Session()
s.headers.update(API_headers)

##########################
## Function definitions ##
##########################


def scrub_issues(issues):
    scrub_array(issues, ("url", "repository_url", "assignee", "events_url"), ("user"))

    for issue in issues:
        ref = list()
        for source in (issue_ref, deleted_issues):
            if issue["number"] in source.keys():
                ref.append(source[issue["number"]])
        comments, etag = retrieve_and_scrub(
            issue["comments_url"], ref, "etag_comments", "comments", scrub_comments
        )
        issue["comments"] = comments
        issue["etag_comments"] = etag
        del issue["comments_url"]

        scrub_labels(issue["labels"])


last_request_limit = 5000


def verbose_get(url, headers=()):
    global last_request_limit
    num_retries = 0
    if not args.quiet:
        output = "Requesting " + url
        if headers:
            output += " with headers " + str(headers)
        output += " (" + str(last_request_limit) + ")"
        print(output)

    while True:
        try:
            if headers:
                response = s.get(url, headers=headers)
            else:
                response = s.get(url)
            response.raise_for_status()
            break
        except requests.exceptions.HTTPError as e:
            if (
                e.response.status_code == "403"
                and "x-ratelimit-reset" in e.response.headers.keys()
            ):
                # We're rate-limited; STALL
                reset = int(e.response.headers["x-ratelimit-reset"])
                time_to_sleep = reset - datetime.datetime.now().timestamp()
                print(
                    "GitHub API rate-limited; waiting for"
                    + str(time_to_sleep)
                    + "seconds"
                )
                time.sleep(time_to_sleep)
                continue
            elif num_retries < 3:
                print(e.request.url)
                print(e.request.headers)
                print(e.response.headers)
                print(e.response.content)
                num_retries += 1
                print("Retrying (" + str(num_retries) + ") after 10 seconds...")
                time.sleep(10)
                continue
            else:
                print(e.request.url)
                print(e.request.headers)
                print(e.response.headers)
                print(e.response.content)
                raise

    if (
        response
        and response.headers
        and "x-ratelimit-remaining" in response.headers.keys()
        and "x-ratelimit-reset" in response.headers.keys()
    ):
        last_request_limit = int(response.headers["x-ratelimit-remaining"])
        if last_request_limit < 1:
            # We're about to be rate-limited; STALL
            reset = int(response.headers["x-ratelimit-reset"])
            time_to_sleep = int(reset - datetime.datetime.now().timestamp()) + 1
            print(
                "GitHub API rate-limited; waiting for " + str(time_to_sleep) + "seconds"
            )
            time.sleep(time_to_sleep)
            last_request_limit = 5000

    return response


# Returns (scrubbed result, etag)
def retrieve_and_scrub(url, references, etag_key, result_key, scrubbing_function):
    headers = dict()
    if not references:
        references = list()

    etags = list()
    for ref in references:
        if etag_key in ref.keys():
            etags.append(ref[etag_key])
    if etags:
        headers["if-none-match"] = ",".join(etags)

    response = verbose_get(url, headers)
    if response.status_code == 304:
        keys = list()
        keys.append(response.headers["etag"])
        keys.append("W/" + response.headers["etag"])
        for ref in references:
            if etag_key in ref.keys():
                if result_key is None:
                    for result_etag in keys:
                        if ref[etag_key] == result_etag:
                            return ref, result_etag
                else:
                    if result_key in ref.keys():
                        for result_etag in keys:
                            if ref[etag_key] == result_etag:
                                return ref[result_key], result_etag

    ## If we get here, it was not a match.  Hopefully a 200....
    if response.status_code != 200:
        ## Should never happen, but just in case....
        response = verbose_get(url)

    scrubbed_result = scrubbing_function(response.json(), references)
    return scrubbed_result, response.headers["etag"]


def scrub_users(user_nodes):
    user_keys_to_keep = ("login", "id")
    for node in user_nodes:
        if node != None:
            for key in [*node]:
                if key not in user_keys_to_keep:
                    del node[key]


def scrub_array(array, keys_to_remove, user_elements):
    user_nodes = list()
    for node in array:
        if node != None:
            for key in keys_to_remove:
                if key in node.keys():
                    del node[key]
            for user_element in user_elements:
                if user_element in node.keys():
                    user_nodes.append(node[user_element])

    scrub_users(user_nodes)


def scrub_commits(commits, not_used):
    scrub_array(commits, (), ("author", "committer"))
    return commits


def scrub_comments(comments, not_used):
    scrub_array(comments, ("url", "issue_url"), ("user"))
    return comments


def scrub_review_comments(review_comments, not_used):
    scrub_array(review_comments, ("url", "pull_request_url", "_links"), ("user"))
    return review_comments


def scrub_labels(labels):
    label_keys_to_keep = ("id", "name")

    for node in labels:
        if node:
            for key in [*node]:
                if key not in label_keys_to_keep:
                    del node[key]


def scrub_PR(pr_details, old_pr_details):
    keys_to_remove = (
        "patch_url",
        "issue_url",
        "statuses_url",
        "_links",
        "review_comment_url",
        "assignee",
    )
    repo_keys_to_keep = ("full_name", "owner")

    for key in keys_to_remove:
        if key in pr_details.keys():
            del pr_details[key]

    user_nodes = list(
        (
            pr_details["user"],
            pr_details["head"]["user"],
            pr_details["base"]["user"],
            pr_details["merged_by"],
        )
    )
    if pr_details["head"]["repo"] != None:
        user_nodes.append(pr_details["head"]["repo"]["owner"])
    if pr_details["base"]["repo"] != None:
        user_nodes.append(pr_details["base"]["repo"]["owner"])

    scrub_users(user_nodes + pr_details["assignees"])

    scrub_labels(pr_details["labels"])

    for node in (pr_details["head"]["repo"], pr_details["base"]["repo"]):
        if node != None:
            for key in [*node]:
                if key not in repo_keys_to_keep:
                    del node[key]

    commits, etag = retrieve_and_scrub(
        pr_details["commits_url"],
        old_pr_details,
        "etag_commits",
        "commits",
        scrub_commits,
    )
    pr_details["commits"] = commits
    pr_details["etag_commits"] = etag
    del pr_details["commits_url"]

    comments, etag = retrieve_and_scrub(
        pr_details["comments_url"],
        old_pr_details,
        "etag_comments",
        "comments",
        scrub_comments,
    )
    pr_details["comments"] = comments
    pr_details["etag_comments"] = etag
    del pr_details["comments_url"]

    review_comments, etag = retrieve_and_scrub(
        pr_details["review_comments_url"],
        old_pr_details,
        "etag_review_comments",
        "review_comments",
        scrub_review_comments,
    )
    pr_details["review_comments"] = review_comments
    pr_details["etag_review_comments"] = etag
    del pr_details["review_comments_url"]

    return pr_details


#####################
## Body of program ##
#####################

## Read in the reference files, if any
issue_ref = dict()
issues_to_scrub = list()
pr_ref = dict()
deleted_issues = dict()

for file_name, to_scrub, dest in (
    (args.refIssues, issues_to_scrub, issue_ref),
    (args.refPullRequests, None, pr_ref),
):
    if file_name:
        with open(file_name, "r") as ref_file:
            raw_reference = json.load(ref_file)

            for element in raw_reference:
                # If there is no "comments" node, it's not usable
                if element != None and "comments" in element.keys():
                    if "number" in element.keys() and not isinstance(
                        element["comments"], int
                    ):
                        dest[element["number"]] = element
                    else:
                        # Scrub anything with a number for the "comments" element
                        # -- not generated by this script
                        if to_scrub is not None:
                            to_scrub.append(element)

# Implicit assumption here that a file is all new or all old; mixing gets dicey.
#
# So, if we had old input, we have to output everything in the new format:
if (args.refIssues and not issue_ref) or (args.refPullRequests and not pr_ref):
    args.omitOld = False

# If we had an old issues file, we can update it to the new format without re-fetching all issues.
scrub_issues(issues_to_scrub)
for issue in issues_to_scrub:
    issue_ref[issue["number"]] = issue

# An old pulls file isn't usable, unfortunately.
if not pr_ref:
    args.refPullRequests = None


## Download from GitHub the full issues list (if no date) or the updated issues list (if date)
url = "https://api.github.com/repos/" + args.repo + "/issues?state=all&per_page=100"
downloaded_issues = list()
if args.lastSuccessDateTime:
    success = dp.parse(args.lastSuccessDateTime)
    url += "&since=" + success.isoformat()

link_match = re.compile('.*<([^>]*)>;[^,]*rel="next".*')
while url:
    response = verbose_get(url)
    response.raise_for_status()

    downloaded_issues += response.json()
    if "link" in response.headers.keys():
        match = link_match.match(response.headers["link"])
        if match:
            url = match.group(1)
            continue
    url = None
    break

pr_issues = list()
issues = list()
for issue in downloaded_issues:
    issue_is_pr = "pull_request" in issue.keys()
    if issue_is_pr and not args.issuesOnly:
        pr_issues.append(issue)
    if not issue_is_pr or not args.issuesOnly:
        issues.append(issue)

    if issue["number"] in issue_ref.keys():
        deleted_issues[issue["number"]] = issue_ref[issue["number"]]
        del issue_ref[issue["number"]]

scrub_issues(issues)

## Ready to output issues
justcopyit = False
if not issues:
    justcopyit = True

## Pick up everything in the reference that wasn't updated by the download
if not args.omitOld:
    issues += issue_ref.values()
    if justcopyit:
        shutil.copyfile(args.refIssues, args.outIssues)

if not justcopyit:
    with open(args.outIssues, "w") as output_file:
        json.dump(issues, output_file, indent=4)

## Same process with PRs.
if not args.issuesOnly:

    # If we didn't have a usable pulls file, we have to process all the old PRs.
    if not args.refPullRequests:
        for issue in issues:
            if "pull_request" in issue.keys() and issue not in pr_issues:
                pr_issues.append(issue)

    prs = list()

    for pr_issue in pr_issues:
        reference = list()
        for source in (pr_ref, deleted_issues):
            if pr_issue["number"] in source.keys():
                reference.append(source[pr_issue["number"]])
        reference.append(pr_issue)
        pr, etag = retrieve_and_scrub(
            pr_issue["pull_request"]["url"], reference, "etag", None, scrub_PR
        )
        if pr_issue["number"] in pr_ref.keys():
            del pr_ref[pr_issue["number"]]
        pr["etag"] = etag
        prs.append(pr)

    if not args.omitOld:
        prs += pr_ref.values()

    with open(args.outPullRequests, "w") as output_file:
        json.dump(prs, output_file, indent=4)

from behave import *
from glob import glob
from subprocess import call
from tempfile import mkdtemp, NamedTemporaryFile
from contextlib import contextmanager
import os
import random
import string


@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)


@given(u"an empty git repo")
def step_impl(context):
    context.test_dir = os.getcwd()
    context.working_dir = mkdtemp()
    context.origin_dir = mkdtemp()
    with cd(context.origin_dir):
        call(["git", "init"])
        call(["git", "checkout", "--orphan", "main"])
        # Need to checkout another branch so that pushes to main work.
        call(["git", "checkout", "-b", "testing"])

    with cd(context.working_dir):
        call(["git", "clone", context.origin_dir, "."])
        call(["git", "checkout", "--orphan", "main"])
        call(["git", "config", "user.name", "Behave Tests"])
        call(["git", "config", "user.email", "behave@example.com"])


@given(u'the default branch is "{branch}"')
def step_impl(context, branch):
    with cd(context.working_dir):
        call(["git", "checkout", "-b", branch])
        call(["git", "push", "--set-upstream", "origin", branch])
        call(["git", "remote", "set-head", "origin", branch])


@given(u"a git repo with no origin")
def step_impl(context):
    context.test_dir = os.getcwd()
    context.working_dir = mkdtemp()
    with cd(context.working_dir):
        call(["git", "init"])
        call(["git", "checkout", "--orphan", "main"])
        call(["git", "config", "user.name", "Behave Tests"])
        call(["git", "config", "user.email", "behave@example.com"])


@given(u"lib is cloned in")
def step_impl(context):
    with cd(context.working_dir):
        call(["ln", "-s", context.test_dir, "lib"])


@given(u"the repo is tagged")
def step_impl(context):
    with cd(context.working_dir):
        md_files = glob("draft-*.md")
        for md in md_files:
            tag = md.replace(".md", "-00")
            call(["git", "tag", "-am", "testing", tag])


@given(u"an empty origin remote is added")
def step_impl(context):
    with cd(context.working_dir):
        call(["git", "remote", "add", "origin", mkdtemp()])


@given(u"a Kramdown draft is created")
def step_impl(context):
    with cd(context.working_dir):
        random_string = "".join(
            random.SystemRandom().choice(string.ascii_lowercase) for n in range(8)
        )
        draft_name = "draft-behave-template-" + random_string
        file_name = draft_name + ".md"
        with open(file_name, "wb") as newFile:
            call(
                [
                    "sed",
                    "-e",
                    "s/draft-hartke-xmpp-stupid/{}/".format(draft_name),
                    "lib/doc/example.md",
                ],
                stdout=newFile,
            )
        call(["git", "add", file_name])
        call(["git", "commit", "-am", "Initial commit of {}".format(draft_name)])


@given(u'a .gitignore with the line "{ignore}"')
def step_impl(context, ignore):
    with cd(context.working_dir):
        with open(".gitignore", "w") as gi:
            gi.write("{}\n".format(ignore))
        call(["git", "add", ".gitignore"])
        call(["git", "commit", "-am", "Create .gitignore with '{}'".format(ignore)])


@given(u"pushed to origin/main")
def step_impl(context):
    with cd(context.working_dir):
        call(["git", "push", "origin", "main"])


@given(u"a git repo with a single Kramdown draft")
def step_impl(context):
    context.execute_steps(
        u"""
        Given an empty git repo
        and lib is cloned in
        and a Kramdown draft is created
        and pushed to origin/main"""
    )


@given(u"a git repo with multiple Kramdown drafts")
def step_impl(context):
    context.execute_steps(
        u"""
        Given a git repo with a single Kramdown draft
        and a Kramdown draft is created
        and pushed to origin/main"""
    )


@given(u"a configured git repo with a Kramdown draft")
def step_impl(context):
    context.execute_steps(u"Given a git repo with a single Kramdown draft")
    with cd(context.working_dir):
        context.result = call(["make", "-f", "lib/setup.mk"])


@given(u"a configured git repo with multiple Kramdown drafts")
def step_impl(context):
    context.execute_steps(u"Given a git repo with multiple Kramdown drafts")
    with cd(context.working_dir):
        context.result = call(["make", "-f", "lib/setup.mk"])

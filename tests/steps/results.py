from behave import *
from contextlib import contextmanager
from subprocess import check_output,check_call
import os
from glob import glob


@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)


@then(u'it succeeds')
def step_impl(context):
    assert context.result == 0


@then(u'it fails')
def step_impl(context):
    assert context.result != 0


@then(u'generates a message "{text}"')
def step_impl(context, text):
    assert context.error.find(text) != -1


@then(u'gitignore lists the xml file')
def step_impl(context):
    with cd(context.working_dir):
        md_files = glob("draft-*.md")
        for md in md_files:
            check_call(["grep", "-q", md.replace(".md", ".xml"), ".gitignore"])


@then(u'generates documents')
def step_impl(context):
    with cd(context.working_dir):
        md_files = glob("draft-*.md")
        for md in md_files:
            txt_file = md.replace(".md", ".txt")
            html_file = md.replace(".md", ".html")
            assert os.path.isfile(txt_file)
            assert os.path.isfile(html_file)


@then(u'documents are added to gh-pages')
def step_impl(context):
    with cd(context.working_dir):
        md_files = glob("draft-*.md")
        ghpages_files = check_output(
            ["git", "ls-tree", "gh-pages", "--name-only", "-r"] ) \
            .decode("utf-8")
        for md in md_files:
            txt_file = md.replace(".md", ".txt")
            html_file = md.replace(".md", ".html")
            assert txt_file in ghpages_files
            assert html_file in ghpages_files


@then(u'a branch is created called "{branch}" containing "{filename}"')
def step_impl(context, branch, filename):
    with cd(context.working_dir):
        files = check_output(
            ["git", "ls-tree", branch, "--name-only", "-r"] ) \
            .decode("utf-8")
        assert filename in files

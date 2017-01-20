from behave import *
from contextlib import contextmanager
from subprocess import check_output
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

@then('it succeeds')
def step_impl(context):
    assert context.result == 0

@then('it fails')
def step_impl(context):
    assert context.result != 0

@then('generates a message "{text}"')
def step_impl(context,text):
    assert context.error.find(text) != -1

@then('generates documents')
def step_impl(context):
    with cd(context.working_dir):
        md_files = glob("draft-*.md")
        for md in md_files:
            txt_file = md.replace(".md",".txt")
            html_file = md.replace(".md",".html")
            assert os.path.isfile(txt_file)
            assert os.path.isfile(html_file)

@then('documents are added to gh-pages')
def step_impl(context):
    with cd(context.working_dir):
        md_files = glob("draft-*.md")
        ghpages_files = check_output( \
            ["git","ls-tree","gh-pages","--name-only"] ) \
            .decode("utf-8")
        for md in md_files:
            txt_file = md.replace(".md",".txt")
            html_file = md.replace(".md",".html")
            assert ghpages_files.find(txt_file) != -1
            assert ghpages_files.find(html_file) != -1

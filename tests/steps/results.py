from behave import *
from contextlib import contextmanager
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
            print("Looking for {} and {}".format(txt_file,html_file))
            assert os.path.isfile(txt_file)
            assert os.path.isfile(html_file)

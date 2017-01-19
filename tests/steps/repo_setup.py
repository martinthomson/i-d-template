from behave import *
from subprocess import call
from tempfile import mkdtemp
from contextlib import contextmanager
import os

@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)

@given('an empty git repo')
def step_impl(context):
    context.test_dir = os.getcwd()
    context.working_dir = mkdtemp()
    context.origin_dir = mkdtemp()
    with cd(context.origin_dir):
      call(["git","init"])
    with cd(context.working_dir):
      call(["git","clone",context.origin_dir,"."])

@given('lib is cloned in')
def step_impl(context):
    with cd(context.working_dir):
      print("Cloning", context.test_dir, "into", context.working_dir)
      call(["git","clone",context.test_dir,"lib"])

@given('a Kramdown draft is created')
def step_impl(context):
    context.execute_steps('''
        Given an empty git repo
        and lib is cloned in''')
    with cd(context.working_dir):
        call(["cp","lib/doc/example.md","draft-hartke-xmpp-stupid.md"])
        call(["git","add","draft-hartke-xmpp-stupid.md"])
        call(["git","commit", "-m", "\"Initial\""])

#@given('a git repo with multiple drafts')
#@given('a git repo with multiple Kramdown drafts')
#@given('a git repo with no origin')

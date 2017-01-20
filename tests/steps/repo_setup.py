from behave import *
from subprocess import call
from tempfile import mkdtemp,NamedTemporaryFile
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
      call(["git","config","user.name","\"Behave Tests\""])
      call(["git","config","user.email","\"behave@example.com\""])

@given('lib is cloned in')
def step_impl(context):
    with cd(context.working_dir):
      print("Cloning", context.test_dir, "into", context.working_dir)
      call(["git","clone",context.test_dir,"lib"])

@given('a Kramdown draft is created')
def step_impl(context):
    with cd(context.working_dir):
        file_name = "TBD.md"
        draft_name = "draft-TBD"
        with NamedTemporaryFile(suffix=".md", prefix="draft-behave-", dir=context.working_dir,delete=False) as newFile:
            file_name = os.path.basename(newFile.name)
            draft_name = os.path.splitext(file_name)[0]
            call(["sed","-e","s/draft-hartke-xmpp-stupid/{}/".format(draft_name),"lib/doc/example.md"],stdout=newFile)
        call(["git","add",file_name])
        call(["git","commit","-am","Initial commit of {}".format(draft_name)])

@given('a git repo with a single Kramdown draft')
def step_impl(context):
    context.execute_steps('''
        Given an empty git repo
        and lib is cloned in
        and a Kramdown draft is created''')

@given('a git repo with multiple Kramdown drafts')
def step_impl(context):
    context.execute_steps('''
        Given a git repo with a single Kramdown draft
        and a Kramdown draft is created''')

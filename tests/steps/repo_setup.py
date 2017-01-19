from behave import given
from subprocess import call
from tempfile import mkdtemp
from os import getcwd,chdir

@given('an empty git repo')
def step_impl(context):
    context.test_dir = getcwd()
    context.working_dir = mkdtemp()
    context.origin_dir = mkdtemp()
    chdir(context.origin_dir)
    call(["git","init"])
    chdir(context.working_dir)
    call(["git","clone",context.origin_dir,"."])

@given('lib is cloned in')
def step_impl(context):
    chdir(context.working_dir)
    call(["git","clone",context.test_dir,"lib"])

#@given('a git repo with a Kramdown draft')

#@given('a git repo with multiple drafts')
#@given('a git repo with multiple Kramdown drafts')
#@given('a git repo with no origin')

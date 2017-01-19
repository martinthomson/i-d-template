from behave import when
from os import chdir
from subprocess import call

@when('the setup script is run')
def step_impl(context):
    chdir(context.working_dir)
    context.result = call(["make","-f","lib/setup.mk"])

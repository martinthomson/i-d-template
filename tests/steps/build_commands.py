from behave import *
from subprocess import call
from contextlib import contextmanager
from tempfile import TemporaryFile
import os
import sys

@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)

def run_with_capture(context,command):
    with cd(context.working_dir), \
      TemporaryFile(mode='w+') as outFile, \
      TemporaryFile(mode='w+') as errFile:
        context.result = call(command, \
            stdout=outFile,stderr=errFile)
        outFile.seek(0)
        context.out = outFile.read()
        errFile.seek(0)
        context.error = errFile.read()
    print(context.out)
    print(context.error, file=sys.stderr)

@when('the setup script is run')
def step_impl(context):
    run_with_capture(context,["make","-f","lib/setup.mk"])

@when('make is run')
def step_impl(context):
    run_with_capture(context,["make"])

@when('make ghpages is run')
def step_impl(context):
    run_with_capture(context,["make","ghpages"])

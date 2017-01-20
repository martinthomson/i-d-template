from behave import *
from subprocess import call
from contextlib import contextmanager
from tempfile import TemporaryFile
import os

@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)

@when('the setup script is run')
def step_impl(context):
    context.outFile = TemporaryFile(mode='w+');
    context.errFile = TemporaryFile(mode='w+');
    with cd(context.working_dir):
        context.result = call(["make","-f","lib/setup.mk"], \
            stdout=context.outFile,stderr=context.errFile)

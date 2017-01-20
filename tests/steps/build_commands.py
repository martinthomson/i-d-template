from behave import *
from subprocess import call
from contextlib import contextmanager
from tempfile import TemporaryFile
from glob import glob
import os
import sys
import fileinput

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

@when('the draft is broken')
def step_impl(context):
    with cd(context.working_dir):
        break_this_file = glob("draft-*.md")[0]
        with fileinput.input(files=break_this_file,inplace=True) as inFile:
            for line in inFile:
                if "RFC2119:" not in line:
                    print(line),
        context.broken_file = break_this_file

@when('git commit is run')
def step_impl(context):
    with cd(context.working_dir):
        run_with_capture(context,["git","commit","-am","Committing broken draft"])

@when('a non-broken draft is committed')
def step_impl(context):
    with cd(context.working_dir):
        drafts = glob("draft-*.md")
        drafts.remove(context.broken_file)
        commit_this_file = drafts[0]
        with open(commit_this_file, "a") as update:
            update.write("# One more appendix\n\nCan you see me?\n");
        call(["git","add",commit_this_file])
        run_with_capture(context,["git","commit","-m","Only the non-broken file"])

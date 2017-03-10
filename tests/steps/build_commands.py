from __future__ import print_function
from behave import *
from subprocess import call
from contextlib import contextmanager
from tempfile import TemporaryFile
from glob import glob
import os
import sys
import fileinput

git_commit = ["git", "-c", "user.name=Behave Tests", "-c",
              "user.email=behave@example.com", "commit"]


@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)


def run_with_capture(context, command):
    with cd(context.working_dir), \
            TemporaryFile(mode='w+') as outFile, \
            TemporaryFile(mode='w+') as errFile:
        context.result = call(command,
                              stdout=outFile, stderr=errFile)
        outFile.seek(0)
        context.out = outFile.read()
        errFile.seek(0)
        context.error = errFile.read()
    print(context.out)
    print(context.error, file=sys.stderr)


@when(u'the setup script is run')
def step_impl(context):
    run_with_capture(context, ["make", "-f", "lib/setup.mk"])


@when(u'make is run')
def step_impl(context):
    run_with_capture(context, ["make"])


@when(u'make "{target}" is run')
def step_impl(context, target):
    run_with_capture(context, ["make", target])


@when(u'the draft is broken')
def step_impl(context):
    with cd(context.working_dir):
        break_this_file = glob("draft-*.md")[0]
        with fileinput.input(files=break_this_file, inplace=True) as inFile:
            for line in inFile:
                if "RFC2119:" not in line:
                    print(line, end='')
        context.broken_file = break_this_file


@when(u'git commit is run')
def step_impl(context):
    with cd(context.working_dir):
        run_with_capture(context, git_commit +
                         ["-am", "Committing broken draft"])


@when(u'a non-broken draft is committed')
def step_impl(context):
    with cd(context.working_dir):
        drafts = glob("draft-*.md")
        drafts.remove(context.broken_file)
        commit_this_file = drafts[0]
        with open(commit_this_file, "a") as update:
            update.write("# One more appendix\n\nCan you see me?\n")
        call(["git", "add", commit_this_file])
        run_with_capture(context, git_commit +
                         ["-m", "Only the non-broken file"])

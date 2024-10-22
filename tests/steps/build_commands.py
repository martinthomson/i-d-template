from __future__ import print_function
from behave import *
from subprocess import call
from contextlib import contextmanager
from tempfile import TemporaryFile
from glob import glob
import os
import sys
import fileinput

git_commit = [
    "git",
    "-c",
    "user.name=Behave Tests",
    "-c",
    "user.email=behave@example.com",
    "commit",
]
offline_make_options = [
    "PUSH_GHPAGES=false",
    "FETCH_ISSUES=false",
    "BRANCH_FETCH=false",
]


@contextmanager
def cd(newdir):
    prevdir = os.getcwd()
    os.chdir(os.path.expanduser(newdir))
    try:
        yield
    finally:
        os.chdir(prevdir)


def run_with_capture(context, command):
    with cd(context.working_dir), TemporaryFile(mode="w+") as outFile, TemporaryFile(
        mode="w+"
    ) as errFile:
        context.result = call(command, stdout=outFile, stderr=errFile)
        outFile.seek(0)
        context.out = outFile.read()
        errFile.seek(0)
        context.error = errFile.read()
    print(context.out)
    print(context.error, file=sys.stderr)


@when("the setup script is run")
def step_impl(context):
    run_with_capture(context, ["make", "-f", "lib/setup.mk"] + offline_make_options)


@when('the setup script is run with "{option}"')
def step_impl(context, option):
    run_with_capture(
        context, ["make", "-f", "lib/setup.mk", option] + offline_make_options
    )


@when("make is run")
def step_impl(context):
    run_with_capture(context, ["make"] + offline_make_options)


@when('make "{target}" is run')
def step_impl(context, target):
    run_with_capture(context, ["make", target] + offline_make_options)


@when('make "{target}" is run with "{option}"')
def step_impl(context, target, option):
    run_with_capture(context, ["make", target, option] + offline_make_options)


@when("the draft is broken")
def step_impl(context):
    import platform

    if any(p in platform.system() for p in ["Darwin", "BSD"]):
        sed_no_backup = ["sed", "-i", ""]
    else:
        sed_no_backup = ["sed", "-i"]
    with cd(context.working_dir):
        break_this = glob("draft-*.md")[0]
        run_with_capture(
            context,
            sed_no_backup + ["-e", "s/TODO Security/{{broken-reference}}/", break_this],
        )
        context.broken_file = break_this


@when("the lib dir is removed")
def step_impl(context):
    run_with_capture(context, ["rm", "-rf", "lib"])


@when("lib is added as a submodule")
def step_impl(context):
    run_with_capture(context, ["git", "submodule", "add", "-f", os.getcwd(), "lib"])


@when("git commit is run")
def step_impl(context):
    with cd(context.working_dir):
        run_with_capture(context, git_commit + ["-am", "Committing broken draft"])


@when("a non-broken draft is committed")
def step_impl(context):
    with cd(context.working_dir):
        drafts = glob("draft-*.md")
        drafts.remove(context.broken_file)
        commit_this_file = drafts[0]
        with open(commit_this_file, "a") as update:
            update.write("# One more appendix\n\nCan you see me?\n")
        call(["git", "add", commit_this_file])
        run_with_capture(context, git_commit + ["-m", "Only the non-broken file"])

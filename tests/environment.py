from behave import *
from shutil import rmtree


def after_scenario(context, scenario):
    if "working_dir" in context:
        rmtree(context.working_dir)
    if "origin_dir" in context:
        rmtree(context.origin_dir)

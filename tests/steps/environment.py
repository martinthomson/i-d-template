from behave import *
from shutil import rmtree

def after_scenario(context,scenario):
    rmtree(context.working_dir)
    rmtree(context.origin_dir)

from shutil import rmtree

def after_scenario(context):
    rmtree(context.working_dir)
    rmtree(context.origin_dir)

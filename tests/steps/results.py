from behave import *

@then('it succeeds')
def step_impl(context):
    assert context.result == 0

@then('it fails')
def step_impl(context):
    assert context.result != 0

#@then('generates a warning "{text}"')
#def step_impl(context):
#    raise NotImplementedError(u'STEP: Then generates a warning "best with just one draft"')

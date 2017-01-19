from behave import then

@then('it succeeds')
def step_impl(context):
    assert context.result == 0

@then('it fails')
def step_impl(context):
    assert context.result != 0

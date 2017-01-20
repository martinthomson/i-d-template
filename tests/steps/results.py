from behave import *

@then('it succeeds')
def step_impl(context):
    assert context.result == 0

@then('it fails')
def step_impl(context):
    assert context.result != 0

@then('generates a message "{text}"')
def step_impl(context,text):
    context.errFile.seek(0)
    messages = context.errFile.read()
    if(messages.find(text) == -1): fail()

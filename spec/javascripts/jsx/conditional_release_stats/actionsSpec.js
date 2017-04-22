define([
  'jsx/conditional_release_stats/helpers/actions',
], ({ createAction, createActions }) => {
  QUnit.module('Conditional Release Stats actions')

  test('creates a new action', () => {
    const actionCreator = createAction('ACTION_ONE')
    const action = actionCreator('payload')

    equal(action.type, 'ACTION_ONE', 'action type match')
    equal(action.payload, 'payload', 'action payload match')
  })

  test('creates multiple actions', () => {
    const actionDefs = ['ACTION_ONE', 'ANOTHER_MORE_COMPLEX_ACTION_NAME']
    const { actionTypes, actions } = createActions(actionDefs)

    equal(actions.actionOne.type, 'ACTION_ONE')
    equal(actionTypes.ACTION_ONE, 'ACTION_ONE')
    equal(actions.anotherMoreComplexActionName.type, 'ANOTHER_MORE_COMPLEX_ACTION_NAME')
    equal(actionTypes.ANOTHER_MORE_COMPLEX_ACTION_NAME, 'ANOTHER_MORE_COMPLEX_ACTION_NAME')
  })
})

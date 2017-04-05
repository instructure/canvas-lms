define([
  'jsx/choose_mastery_path/actions',
  'jsx/choose_mastery_path/reducer',
], (actions, reducer) => {
  QUnit.module('Choose Mastery Path Reducer')

  const reduce = (action, state = {}) => {
    return reducer(state, action)
  }

  test('sets error', () => {
    const newState = reduce(actions.setError('ERROR'))
    equal(newState.error, 'ERROR', 'error updated')
  })

  test('sets options', () => {
    const options = [
      {
        assignments: [
          {
            name: 'Ch 2 Quiz',
            type: 'quiz',
            points: 10,
            due_date: 'Aug 20',
          },
        ],
      },
    ]
    const newState = reduce(actions.setOptions(options))
    deepEqual(newState.options, options, 'options updated')
  })

  test('select option', () => {
    const newState = reduce({ type: actions.SELECT_OPTION, payload: 1 })
    equal(newState.selectedOption, 1, 'option selected')
  })
})

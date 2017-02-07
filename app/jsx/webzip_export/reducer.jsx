define([
  'redux-actions',
  './actions',
], (ReduxActions, Actions) => {
  const { handleActions } = ReduxActions

  const reducer = handleActions({
    [Actions.keys.CREATE_NEW_EXPORT]: (state = {}, action) => ({
      exports: [
        ...state.exports,
        {date: action.payload.date, link: action.payload.link}
      ]
    })
  })

  return reducer
})

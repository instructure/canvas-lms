define([
  'redux-actions',
  './api-client',
], ({ createAction }, api) => {
  const actions = {}

  actions.SET_ERROR = 'SET_ERROR'
  actions.setError = createAction(actions.SET_ERROR)

  actions.SET_OPTIONS = 'SET_OPTIONS'
  actions.setOptions = createAction(actions.SET_OPTIONS)

  actions.SELECT_OPTION = 'SELECT_OPTION'
  actions.selectOption = (option) => {
    return (dispatch, getState) => {
      dispatch({ type: actions.SELECT_OPTION, payload: option })

      api.selectOption(getState(), option)
        .then(() => {},
        (err) => {
          dispatch({ type: actions.SELECT_OPTION, payload: null })
          dispatch(actions.setError(err))
        })
    }
  }

  return actions
})

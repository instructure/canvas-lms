define([
  'redux-actions',
  './api-client',
], ({ createActions }, api) => {
  const actionDefs = [
    'VALIDATE_USERS_START',
    'VALIDATE_USERS_SUCCESS',
    'VALIDATE_USERS_ERROR',

    'CREATE_USERS_START',
    'CREATE_USERS_SUCCESS',
    'CREATE_USERS_ERROR',

    'ENROLL_USERS_START',
    'ENROLL_USERS_SUCCESS',
    'ENROLL_USERS_ERROR',
  ]

  const actionTypes = actionDefs.reduce((types, action) => {
    types[action] = action
    return types
  }, {})

  const actions = createActions(...actionDefs)

  actions.validateUsers = (users, searchType) => {
    return (dispatch, getState) => {
      dispatch(actions.validateUsersStart())
      api.validateUsers(getState(), users, searchType)
        .then(res => dispatch(actions.validateUsersSuccess(res.data)))
        .catch(err => dispatch(actions.validateUsersError(err.response.data)))
    }
  }

  actions.createUsers = (users) => {
    return (dispatch, getState) => {
      dispatch(actions.createUsersStart())
      api.createUsers(getState(), users)
        .then(res => dispatch(actions.createUsersSuccess(res.data)))
        .catch(err => dispatch(actions.createUsersError(err.response.data)))
    }
  }

  actions.enrollUsers = (users, role, section) => {
    return (dispatch, getState) => {
      dispatch(actions.enrollUsersStart())
      api.enrollUsers(getState(), users, role, section)
        .then(res => dispatch(actions.enrollUsersSuccess(res.data)))
        .catch(err => dispatch(actions.enrollUsersError(err.response.data)))
    }
  }

  return { actions, actionTypes }
})

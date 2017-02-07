define([
  'underscore',
  'redux',
  'redux-actions',
  '../actions',
  '../store'
], (_, redux, { handleActions }, {actions, actionTypes}, {defaultState}) => handleActions({
  [actionTypes.ENROLL_USERS_SUCCESS]: (/* state, action */) => (
    // all the users are enrolled, clear the list
    (defaultState.usersToBeEnrolled)
  ),
  // action.payload: [users]
  [actionTypes.ENQUEUE_USERS_TO_BE_ENROLLED]: (state, action) => (
    // replace state with the incoming array
    action.payload
  ),
  [actionTypes.RESET]: (state, action) => (
    (!action.payload || action.payload.includes('usersToBeEnrolled')) ? defaultState.usersToBeEnrolled : state
  )
}, defaultState.usersToBeEnrolled));

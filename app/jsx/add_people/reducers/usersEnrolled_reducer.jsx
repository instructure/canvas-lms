define([
  'redux',
  'redux-actions',
  '../actions',
  '../store'
], (redux, { handleActions }, {actionTypes}) => handleActions({
  [actionTypes.ENROLL_USERS_SUCCESS]: (/* state, action */) => true,
  [actionTypes.RESET]: (/* state, action */) => false
}, false));

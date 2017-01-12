define([
  'redux',
  'redux-actions',
  './store',
  './actions',
  './reducers/apiState_reducer',
  './reducers/inputParams_reducer',
  './reducers/userValidationResult_reducer',
  './reducers/usersToBeEnrolled_reducer',
  './reducers/usersEnrolled_reducer'
], ({ combineReducers }, { handleActions }, {defaultState}, {actions, actionTypes},
    apiState, inputParams, userValidationResult, usersToBeEnrolled, usersEnrolled) => {
  const reducer = combineReducers({
    courseParams: handleActions({}, defaultState.courseParams),
    apiState,
    inputParams,
    userValidationResult,
    usersToBeEnrolled,
    usersEnrolled
  });

  return reducer;
});

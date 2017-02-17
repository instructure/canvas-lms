define([
  'redux',
  'redux-actions',
  './actions',
], ({ combineReducers }, { handleActions }, { actionTypes }) => {
  const identity = (defaultState = null) => {
    return state => state === undefined ? defaultState : state
  }

  return combineReducers({
    accountId: identity(),
    course: identity(),
    terms: identity([]),
    subAccounts: identity([]),
    isLoadingCourses: handleActions({
      [actionTypes.LOAD_COURSES_START]: () => true,
      [actionTypes.LOAD_COURSES_SUCCESS]: () => false,
      [actionTypes.LOAD_COURSES_FAIL]: () => false,
    }, false),
    courses: handleActions({
      [actionTypes.LOAD_COURSES_SUCCESS]: (state, action) => action.payload,
    }, []),
    errors: (state = [], action) => {
      return action.error
        ? state.concat([action.payload.message])
        : state
    },
  })
})

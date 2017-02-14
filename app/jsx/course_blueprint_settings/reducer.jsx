define([
  'redux',
  'redux-actions',
  './actions',
], ({ combineReducers }, { handleActions }, actions) => {
  const identity = (defaultState = null) => {
    return state => state === undefined ? defaultState : state
  }

  return combineReducers({
    course: identity(),
    terms: identity([]),
    subAccounts: identity([]),
  })
})

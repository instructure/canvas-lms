define([
  'redux',
  'redux-thunk',
], ({ createStore, applyMiddleware }, ReduxThunk) => {
  // returns createStore(reducer, initialState)
  return applyMiddleware(
    ReduxThunk
  )(createStore)
})

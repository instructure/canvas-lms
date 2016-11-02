define([
  'redux',
  'redux-thunk',
], ({ createStore, applyMiddleware }, {default:ReduxThunk}) => {
  // returns createStore(reducer, initialState)
  return applyMiddleware(
    ReduxThunk
  )(createStore)
})

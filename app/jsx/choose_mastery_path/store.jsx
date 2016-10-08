define([
  'redux',
  'redux-thunk',
  './reducer',
], (Redux, ReduxThunk, rootReducer) => {
  const { createStore, applyMiddleware } = Redux

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore)

  return function configStore (initialState) {
    return createStoreWithMiddleware(rootReducer, initialState)
  }
})

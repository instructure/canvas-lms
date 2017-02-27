define([
  'redux',
  'redux-thunk',
  './reducer',
], (Redux, {default: ReduxThunk}, rootReducer) => {
  const { createStore, applyMiddleware } = Redux

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore)

  return function configStore (initialState) {
    return createStoreWithMiddleware(rootReducer, initialState)
  }
})

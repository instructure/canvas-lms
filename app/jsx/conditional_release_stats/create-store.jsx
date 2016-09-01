define([
  'redux',
  'redux-thunk',
  './reducers/root-reducer',
], (Redux, ReduxThunk, rootReducer) => {
  const { createStore, applyMiddleware } = Redux

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore)

  return function configureStore (initialState) {
    return createStoreWithMiddleware(rootReducer, initialState)
  }
})

define([
  'redux',
  'redux-thunk',
  'redux-logger',
  './reducer',
], (Redux, {default: ReduxThunk}, ReduxLogger, rootReducer) => {
  const { createStore, applyMiddleware } = Redux
  const logger = ReduxLogger()

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk,
    logger
  )(createStore)

  return function configStore (initialState) {
    return createStoreWithMiddleware(rootReducer, initialState)
  }
})

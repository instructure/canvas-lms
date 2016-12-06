define([
  'redux',
  'redux-thunk',
  'redux-logger',
  '../reducer',
], (Redux, {default: ReduxThunk}, reduxLogger, reducer) => {
  const { createStore, applyMiddleware } = Redux

  const logger = reduxLogger()

  const createStoreWithMiddleware = applyMiddleware(
    logger,
    ReduxThunk
  )(createStore)

  return function configureStore (state = {}) {
    return createStoreWithMiddleware(reducer, state)
  }
})

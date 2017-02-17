define([
  'redux',
  'redux-thunk',
  'redux-logger',
  '../reducer',
  './initialState'
], function (Redux, {default:ReduxThunk}, ReduxLogger, reducer, initialState) {

  const { createStore, applyMiddleware } = Redux;

  const logger = ReduxLogger();

  const createStoreWithMiddleware = applyMiddleware(
    logger,
    ReduxThunk
  )(createStore);

  return function configureStore (state = initialState) {
    return createStoreWithMiddleware(reducer, state);
  };
});

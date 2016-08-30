define([
  'redux',
  'redux-thunk',
  'redux-logger',
  '../reducer',
  './initialState'
], function (Redux, ReduxThunk, ReduxLogger, reducer, initialState) {

  const { createStore, applyMiddleware } = Redux;

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk,
    ReduxLogger
  )(createStore);

  return function configureStore (state = initialState) {
    return createStoreWithMiddleware(reducer, state);
  };
});

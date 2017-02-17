define([
  'redux',
  'redux-thunk',
  '../reducer'
], function (Redux, {default:ReduxThunk}, rootReducer) {

  const { createStore, applyMiddleware } = Redux;

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore);

  return function configureStore (initialState) {
    return createStoreWithMiddleware(rootReducer, initialState);
  };
});

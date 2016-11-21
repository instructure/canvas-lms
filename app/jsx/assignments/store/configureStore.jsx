define([
  'redux',
  'redux-thunk',
  '../reducers/rootReducer'
], function (Redux, {default:ReduxThunk}, rootReducer) {

  var { createStore, applyMiddleware } = Redux;

  var createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore);

  return function configureStore (initialState) {
    return createStoreWithMiddleware(rootReducer, initialState);
  };
});

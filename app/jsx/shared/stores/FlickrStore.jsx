define([
  'redux',
  'redux-thunk',
  '../reducers/FlickrReducer',
  './FlickrInitialState'
], function (Redux, ReduxThunk, FlickrReducer, FlickrInitialState) {

  const { createStore, applyMiddleware } = Redux;

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore);

  return createStoreWithMiddleware(FlickrReducer, FlickrInitialState);

});
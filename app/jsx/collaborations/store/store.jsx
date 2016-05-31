define([
  'redux',
  '../reducers/collaborationsReducer'
], ({createStore, combineReducers}, collaborationsReducer) => {
  return createStore(combineReducers({
    collaborationsReducer
  }))
});

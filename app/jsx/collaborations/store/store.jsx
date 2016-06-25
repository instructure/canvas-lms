define([
  'redux',
  'redux-thunk',
  '../reducers/ltiCollaboratorsReducer',
  '../reducers/listCollaborationsReducer'
], (Redux, ReduxThunk, ltiCollaboratorsReducer, listCollaborationsReducer) => {
  const { createStore, applyMiddleware } = Redux;

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore);

  const collaboratorationsReducer = Redux.combineReducers({
    ltiCollaborators: ltiCollaboratorsReducer,
    listCollaborations: listCollaborationsReducer
  })

  return createStoreWithMiddleware(collaboratorationsReducer);
});

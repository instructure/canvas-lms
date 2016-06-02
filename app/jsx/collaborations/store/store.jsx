define([
  'redux',
  'redux-thunk',
  '../reducers/ltiCollaboratorsReducer',
  '../reducers/listCollaborationsReducer',
  '../reducers/deleteCollaborationReducer'
], (Redux, ReduxThunk, ltiCollaboratorsReducer, listCollaborationsReducer, deleteCollaborationReducer) => {
  const { createStore, applyMiddleware } = Redux;

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore);

  const collaboratorationsReducer = Redux.combineReducers({
    ltiCollaborators: ltiCollaboratorsReducer,
    listCollaborations: listCollaborationsReducer,
    deleteCollaboration: deleteCollaborationReducer
  })

  return createStoreWithMiddleware(collaboratorationsReducer);
});

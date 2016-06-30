define([
  'redux',
  'redux-thunk',
  '../reducers/ltiCollaboratorsReducer',
  '../reducers/listCollaborationsReducer',
  '../reducers/deleteCollaborationReducer',
  '../reducers/createCollaborationReducer'
], (Redux, ReduxThunk, ltiCollaboratorsReducer, listCollaborationsReducer, deleteCollaborationReducer, createCollaborationReducer) => {
  const { createStore, applyMiddleware } = Redux;

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore);

  const collaboratorationsReducer = Redux.combineReducers({
    ltiCollaborators: ltiCollaboratorsReducer,
    listCollaborations: listCollaborationsReducer,
    deleteCollaboration: deleteCollaborationReducer,
    createCollaboration: createCollaborationReducer
  });

  return createStoreWithMiddleware(collaboratorationsReducer);
});

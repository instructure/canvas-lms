define([
  'redux',
  'redux-thunk',
  '../reducers/ltiCollaboratorsReducer',
  '../reducers/listCollaborationsReducer',
  '../reducers/deleteCollaborationReducer',
  '../reducers/createCollaborationReducer',
  '../reducers/updateCollaborationReducer'
], (Redux, ReduxThunk, ltiCollaboratorsReducer, listCollaborationsReducer, deleteCollaborationReducer, createCollaborationReducer, updateCollaborationReducer) => {
  const { createStore, applyMiddleware } = Redux;

  const createStoreWithMiddleware = applyMiddleware(
    ReduxThunk
  )(createStore);

  const collaboratorationsReducer = Redux.combineReducers({
    ltiCollaborators: ltiCollaboratorsReducer,
    listCollaborations: listCollaborationsReducer,
    deleteCollaboration: deleteCollaborationReducer,
    createCollaboration: createCollaborationReducer,
    updateCollaboration: updateCollaborationReducer
  });

  return createStoreWithMiddleware(collaboratorationsReducer);
});

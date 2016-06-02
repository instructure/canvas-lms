define([
  'axios'
], (axios) => {
  const actions = {};

  actions.LIST_COLLABORATIONS_START = 'LIST_COLLABORATIONS_START';
  actions.listCollaborationsStart = () => ({ type: actions.LIST_COLLABORATIONS_START });

  actions.LIST_COLLABORATIONS_SUCCESSFUL = 'LIST_COLLABORATIONS_SUCCESSFUL';
  actions.listCollaborationsSuccessful = (collaborations) => ({ type: actions.LIST_COLLABORATIONS_SUCCESSFUL, payload: collaborations });

  actions.LIST_COLLABORATIONS_FAILED = 'LIST_COLLABORATIONS_FAILED';
  actions.listCollaborationsFailed = (error) => ({ type: actions.LIST_COLLABORATIONS_FAILED, error: true, payload: error });

  actions.LIST_LTI_COLLABORATIONS_START = 'LIST_LTI_COLLABORATIONS_START';
  actions.listLTICollaborationsStart = () => ({ type: actions.LIST_LTI_COLLABORATIONS_START });

  actions.LIST_LTI_COLLABORATIONS_SUCCESSFUL = 'LIST_LTI_COLLABORATIONS_SUCCESSFUL';
  actions.listLTICollaborationsSuccessful = (tools) => ({ type: actions.LIST_LTI_COLLABORATIONS_SUCCESSFUL, payload: tools});

  actions.LIST_LTI_COLLABORATIONS_FAILED = 'LIST_LTI_COLLABORATIONS_FAILED';
  actions.listLTICollaborationsFailed = (error) => ({ type: actions.LIST_LTI_COLLABORATIONS_FAILED, payload: error, error:true });

  actions.DELETE_COLLABORATION_START = 'DELETE_COLLABORATION_START';
  actions.deleteCollaborationStart = () => ({ type: actions.DELETE_COLLABORATION_START });

  actions.DELETE_COLLABORATION_SUCCESSFUL = 'DELETE_COLLABORATION_SUCCESSFUL';
  actions.deleteCollaborationSuccessful = (deletedCollaborationId) => ({ type: actions.DELETE_COLLABORATION_SUCCESSFUL, payload: deletedCollaborationId });

  actions.DELETE_COLLABORATION_FAILED = 'DELETE_COLLABORATION_FAILED';
  actions.deleteCollaborationFailed = (error) => ({ type: actions.DELETE_COLLABORATION_FAILED, payload: error, error: true });

  actions.getCollaborations = (context, contextId) => {
    return (dispatch) => {
      dispatch(actions.listCollaborationsStart());

      let url = `/api/v1/${context}/${contextId}/collaborations`;
      $.getJSON(url)
        .success((collaborations) => dispatch(actions.listCollaborationsSuccessful(collaborations)))
        .fail((err) => dispatch(actions.listCollaborationsFailed(err)));
    }
  };

  actions.getLTICollaborators = (context, contextId) => {
    return (dispatch) => {
      dispatch(actions.listLTICollaborationsStart());
      $.getJSON(`/api/v1/${context}/${contextId}/external_tools?placement=collaboration`)
      .success(tools => {
        dispatch(actions.listLTICollaborationsSuccessful(tools));
      })
      .fail(error => {
        dispatch(actions.listLTICollaborationsFailed(error));
      });
    }
  };

  actions.deleteCollaboration = (context, contextId, collaborationId) => {
    return (dispatch) => {
      dispatch(actions.deleteCollaborationStart());

      let url = `/api/v1/${context}/${contextId}/collaborations/${collaborationId}`
      axios.delete(url)
        .then((response) => {
          dispatch(actions.deleteCollaborationSuccessful(collaborationId))
          dispatch(actions.getCollaborations(context, contextId))
        })
        .catch((err) => dispatch(actions.deleteCollaborationFailed(err)));
    }
  }

  return actions
})

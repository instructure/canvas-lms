define([
], () => {
  const actions = {}

  actions.LIST_COLLABORATIONS_START = 'LIST_COLLABORATIONS_START'
  actions.listCollaborationsStart = () => ({ type: actions.LIST_COLLABORATIONS_START })

  actions.LIST_COLLABORATIONS_SUCCESSFUL = 'LIST_COLLABORATIONS_SUCCESSFUL'
  actions.listCollaborationsSuccessful = (collaborations) => ({ type: actions.LIST_COLLABORATIONS_SUCCESSFUL, payload: collaborations })

  actions.LIST_COLLABORATIONS_FAILED = 'LIST_COLLABORATIONS_FAILED'
  actions.listCollaborationsFailed = (error) => ({ type: actions.LIST_COLLABORATIONS_FAILED, error: true, payload: error })

  actions.LIST_LTI_COLLABORATIONS_START = 'LIST_LTI_COLLABORATIONS_START'
  actions.listLTICollaborationsStart = () => ({ type: actions.LIST_LTI_COLLABORATIONS_START })

  actions.LIST_LTI_COLLABORATIONS_SUCCESSFUL = 'LIST_LTI_COLLABORATIONS_SUCCESSFUL'
  actions.listLTICollaborationsSuccessful = (tools) => ({ type: actions.LIST_LTI_COLLABORATIONS_SUCCESSFUL, payload: tools})

  actions.LIST_LTI_COLLABORATIONS_FAILED = 'LIST_LTI_COLLABORATIONS_FAILED'
  actions.listLTICollaborationsFailed = (error) => ({ type: actions.LIST_LTI_COLLABORATIONS_FAILED, payload: error, error:true })

  actions.getCollaborations = (context, contextId) => {
    return (dispatch) => {
      dispatch(actions.listCollaborationsStart());

      let url = `/api/v1/${context}/${contextId}/collaborations`;
      $.getJSON(url)
        .success((collaborations) => dispatch(actions.listCollaborationsSuccessful(collaborations)))
        .fail((err) => dispatch(actions.listCollaborationsFailed(err)));
    }
  }

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
  }

  return actions
})

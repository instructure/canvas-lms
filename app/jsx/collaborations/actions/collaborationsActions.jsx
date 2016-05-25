define([
], () => {
  const actions = {}
   
  actions.LIST_COLLABORATIONS_START = 'LIST_COLLABORATIONS_START'
  actions.listCollaborationsStart = () => ({ type: actions.LIST_COLLABORATIONS_START }),

  actions.LIST_COLLABORATIONS_SUCCESSFUL = 'LIST_COLLABORATIONS_SUCCESSFUL'
  actions.listCollaborationsSuccessful = (collaborations) => ({ type: actions.LIST_COLLABORATIONS_SUCCESSFUL, payload: collaborations }),

  actions.LIST_COLLABORATIONS_FAILED = 'LIST_COLLABORATIONS_FAILED'
  actions.listCollaborationsFailed = (error) => ({ type: actions.LIST_COLLABORATIONS_FAILED, error: true, payload: error })

  actions.getCollaborations = () => {
    actions.listCollaborationsStart();

    //do some async work

    //on success
    actions.listCollaborationsSuccessful(collaborations);

    //on failure
    actions.listCollaborationsFailed(error)
  }

  return actions
})

define([
  '../actions/collaborationsActions'
], (ACTION_NAMES) => {
  const initialState = {
    createCollaborationPending: false,
    createCollaborationSuccessful: false,
    createCollaborationError: null
  }

  let createHandlers = {
    [ACTION_NAMES.CREATE_COLLABORATION_START]: (state, action) => {
      return {
        ...state,
        createCollaborationPending: true,
        createCollaborationSuccessful: false,
        createCollaborationError: null
      }
    },
    [ACTION_NAMES.CREATE_COLLABORATION_SUCCESSFUL]: (state, action) => {
      return {
        ...state,
        createCollaborationPending: false,
        createCollaborationSuccessful: true
      }
    },
    [ACTION_NAMES.CREATE_COLLABORATION_FAILED]: (state, action) => {
      return {
        ...state,
        createCollaborationPending: false,
        createCollaborationError: action.payload
      }
    }
  }

  return (state = initialState, action) => {
    if (createHandlers[action.type]) {
      return createHandlers[action.type](state, action)
    } else {
      return state
    }
  }
})

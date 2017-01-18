define([
  'redux',
  '../actions/collaborationsActions'
], (redux, ACTION_NAMES) => {
  let initialState = {
    deleteCollaborationPending: false,
    deleteCollaborationSuccessful: false,
    deleteCollaborationError: null
  }

  let deleteHandlers = {
    [ACTION_NAMES.DELETE_COLLABORATION_START]: (state, action) => {
      return {
        ...state,
        deleteCollaborationPending: true,
        deleteCollaborationSuccessful: false,
        deleteCollaborationError: null
      };
    },
    [ACTION_NAMES.DELETE_COLLABORATION_SUCCESSFUL]: (state, action) => {
      return {
        ...state,
        deleteCollaborationPending: false,
        deleteCollaborationSuccessful: true
      }
    },
    [ACTION_NAMES.DELETE_COLLABORATION_FAILED]: (state, action) => {
      return {
        ...state,
        deleteCollaborationPending: false,
        deleteCollaborationError: action.payload
      }
    }
  };

  return (state = initialState, action) => {
    if (deleteHandlers[action.type]) {
      return deleteHandlers[action.type](state, action)
    } else {
      return state
    }
  }
})

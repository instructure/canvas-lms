import redux from 'redux'
import ACTION_NAMES from '../actions/collaborationsActions'
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

export default (state = initialState, action) => {
    if (deleteHandlers[action.type]) {
      return deleteHandlers[action.type](state, action)
    } else {
      return state
    }
  }

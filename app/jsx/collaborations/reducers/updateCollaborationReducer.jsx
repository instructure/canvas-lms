define([
  'redux',
  '../actions/collaborationsActions'
], (redux, ACTION_NAMES) => {
  let initialState = {
    updateCollaborationPending: false,
    updateCollaborationSuccessful: false,
    updateCollaborationError: null
  };

  let updateHandlers = {
    [ACTION_NAMES.UPDATE_COLLABORATION_START]: (state, action) => {
      return {
        ...state,
        updateCollaborationPending: true,
        updateCollaborationSuccessful: false,
        updateCollaborationError: null
      }
    },
    [ACTION_NAMES.UPDATE_COLLABORATION_SUCCESSFUL]: (state, action) => {
      return {
        ...state,
        updateCollaborationPending: false,
        updateCollaborationSuccessful: true
      }
    },
    [ACTION_NAMES.UPDATE_COLLABORATION_FAILED]: (state, action) => {
      return {
        ...state,
        updateCollaborationPending: false,
        updateCollaborationError: action.payload
      }
    }
  };

  let updateReducer = (state = initialState, action) => {
    if (updateHandlers[action.type]) {
      return updateHandlers[action.type](state, action);
    } else {
      return state;
    }
  };

  return updateReducer;
});

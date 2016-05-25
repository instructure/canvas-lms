define([
  'redux',
  '../actions/collaborationsActions'
], (redux, ACTION_NAMES) => {
  let initialState = {
    listCollaborationsPending: false,
    listCollaborationsSuccessful: false,
    listCollaborationsError: null,
    collaborations: [],
  }

  let collaborationsHandlers = {
    [ACTION_NAMES.LIST_COLLABORATIONS_START]: (state, action) => {
      return {
        ...state,
        listCollaborationsPending: true,
        listCollaborationsSuccessful: false,
        listCollaborationsError: null
      };
    },
    [ACTION_NAMES.LIST_COLLABORATIONS_SUCCESSFUL]: (state, action) => {
      return {
        ...state,
        listCollaborationsPending: false,
        listCollaborationsSuccessful: true,
        collaborations: action.payload
      }
    },
    [ACTION_NAMES.LIST_COLLABORATIONS_FAILED]: (state, action) => {
      return {
        ...state,
        listCollaborationsPending: false,
        listCollaborationsError: action.payload
      }
    }
  };

  return (state = initialState, action) => {
    if (collaborationsHandlers[action.type]) {
      return collaborationsHandlers[action.type](state, action)
    } else {
      return state
    }
  }
})

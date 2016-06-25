define([
  'redux',
  '../actions/collaborationsActions',
], (redux, ACTION_NAMES) => {
  let initialState = {
    listCollaborationsPending: false,
    listCollaborationsSuccessful: false,
    listCollaborationsError: null,
    collaborations: [],
  }

  return (state = initialState, action) => {
    switch (action.type) {
      case ACTION_NAMES.LIST_COLLABORATIONS_START:
        return {
          ...state,
          listCollaborationsPending: true,
          listCollaborationsSuccessful: false,
          listCollaborationsError: null
        };

      case ACTION_NAMES.LIST_COLLABORATIONS_SUCCESSFUL:
        return {
          ...state,
          listCollaborationsPending: false,
          listCollaborationsSuccessful: true,
          collaborations: action.payload
        };

      case ACTION_NAMES.LIST_COLLABORATIONS_FAILED:
        return {
          ...state,
          listCollaborationsPending: false,
          listCollaborationsError: action.payload
        };

      default:
        return state;
    }
  };
})

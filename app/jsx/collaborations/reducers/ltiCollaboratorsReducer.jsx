define([
  'redux',
  'underscore'
], (redux, _) => {
  let initialState = {
    listLTICollaboratorsPending: false,
    listLTICollaboratorsSuccessful: false,
    listLTICollaboratorsError: null,
    ltiCollaboratorsData : [],
  }
  const ltiCollaboratorsHandlers = {
    LIST_LTI_COLLABORATIONS_START: (state, action) => {
      state.listLTICollaboratorsPending = true;
      state.listLTICollaboratorsSuccessful = false;
      state.listLTICollaboratorsError = null;
      return state
    },

    LIST_LTI_COLLABORATIONS_SUCCESSFUL: (state, action) => {
      state.listLTICollaboratorsPending = false;
      state.listLTICollaboratorsSuccessful = true;
      state.ltiCollaboratorsData = action.payload;
      return state
    },
    LIST_LTI_COLLABORATIONS_FAILED: (state, action) => {
      state.listLTICollaboratorsPending = false;
      state.listLTICollaboratorsError = action.payload;
      return state
    }
  };

  const ltiCollaborators= (state = initialState, action) => {
    if (ltiCollaboratorsHandlers[action.type]) {
      const newState = _.extend({}, state);
      return ltiCollaboratorsHandlers[action.type](newState, action);
    } else {
      return state;
    }
  };
  return ltiCollaborators;

})

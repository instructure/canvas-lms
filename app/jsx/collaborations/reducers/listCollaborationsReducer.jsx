define([
  'redux',
  '../actions/collaborationsActions'
], (redux, ACTION_NAMES) => {
  let initialState = {
    listCollaborationsPending: false,
    listCollaborationsSuccessful: false,
    listCollaborationsError: null,
    list: [],
  }

  let collaborationsHandlers = {
    [ACTION_NAMES.LIST_COLLABORATIONS_START]: (state, action) => {
      return {
        ...state,
        list: action.payload ? [] : state.list,
        listCollaborationsPending: true,
        listCollaborationsSuccessful: false,
        listCollaborationsError: null
      };
    },
    [ACTION_NAMES.LIST_COLLABORATIONS_SUCCESSFUL]: (state, action) => {
      let list = state.list.slice()
      list.push(...action.payload.collaborations)
      return {
        ...state,
        listCollaborationsPending: false,
        listCollaborationsSuccessful: true,
        list,
        nextPage: action.payload.next
      }
    },
    [ACTION_NAMES.LIST_COLLABORATIONS_FAILED]: (state, action) => {
      return {
        ...state,
        listCollaborationsPending: false,
        listCollaborationsError: action.payload
      }
    },
    [ACTION_NAMES.CREATE_COLLABORATION_SUCCESSFUL]: (state, action) => {
      return {
        ...state,
        list: [],
        nextPage: null
      }
    },
    [ACTION_NAMES.DELETE_COLLABORATION_SUCCESSFUL]: (state, action) => {
      return {
        ...state,
        list: [],
        nextPage: null
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

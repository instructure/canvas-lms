define([
  'redux',
  'underscore',
  '../actions/conditional-actions',
  'jsx/cyoe_assignment_sidebar/store/default-state'
], (Redux, _, Actions, defaultState) => {

  const {combineReducers} = Redux;
  const getPayload = (state, action) => action.payload;

  const handleActions = (actionHandler) => {
    return (state = {}, action) => {
      if(actionHandler[action.type]) {
        const newState = _.extend({}, state);
        return actionHandler[action.type](newState, action);
      } else {
        return state;
      }
    }
  };

  const global_shared = handleActions({
    [Actions.SET_ERRORS]: (state, action) => {
      state.errors = [...action.payload, ...state.errors];
      return state;
    },
    [Actions.OPEN_SIDEBAR]: (state, action) => {
      state.open = getPayload(state, action);
      return state;
    },
    [Actions.CLOSE_SIDEBAR]: (state, action) => {
      state.open = null;
      return state;
    }
  });

  const ranges = handleActions({
    [Actions.SET_SCORING_RANGES]: getPayload,
    [Actions.SET_BAR_AT_INDEX]: (state = defaultState.ranges, action) => {
      const newBar = action.payload
      state.ranges = _.extend({}, state.ranges, { newBar });
      return state;
    }
  });

  const rule = handleActions({
    [Actions.SET_RULE]: getPayload
  });

  const assignment = handleActions({
    [Actions.SET_ASSIGNMENT]: getPayload
  });

  const enrolled = handleActions({
    [Actions.SET_ENROLLED]: getPayload
  });

  return combineReducers({
    ranges,
    rule,
    enrolled,
    assignment,
    global_shared
  });

});

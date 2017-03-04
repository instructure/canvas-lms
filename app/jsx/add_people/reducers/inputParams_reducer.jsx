define([
  'redux',
  'redux-actions',
  '../actions',
  '../store'
], (redux, { handleActions }, {actions, actionTypes}, {defaultState}) => handleActions({
  [actionTypes.SET_INPUT_PARAMS]: function setReducer (state, action) {
      // replace state with new values
    return action.payload;
  },
  [actionTypes.RESET]: function resetReducer (state, action) {
    // reset to default state, except for canReadSIS, which has to persist across invocations
    const resetState = Object.assign({}, defaultState.inputParams, {canReadSIS: state.canReadSIS});
    return (!action.payload || action.payload.includes('inputParams')) ? resetState : state;
  }
}, defaultState.inputParams));

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
    return (!action.payload || action.payload.includes('inputParams')) ? defaultState.inputParams : state;
  }
}, defaultState.inputParams));

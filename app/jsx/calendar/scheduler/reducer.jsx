define([
  'redux-actions',
  './actions'
], (ReduxActions, SchedulerActions) => {

  const { handleActions } = ReduxActions;

  const reducer = handleActions({
    [SchedulerActions.keys.SET_FIND_APPOINTMENT_MODE]: (state, action) => {
      return {
        inFindAppointmentMode: action.payload
      }
    }
  });

  return reducer;

});

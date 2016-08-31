define([
  'redux-actions',
  './actions',
  './store/initialState'
], (ReduxActions, SchedulerActions, initialState) => {

  const { handleActions } = ReduxActions;

  const reducer = handleActions({
    [SchedulerActions.keys.SET_FIND_APPOINTMENT_MODE]: (state = initialState, action) => {
      return {
        ...state,
        inFindAppointmentMode: action.payload
      }
    },
    [SchedulerActions.keys.SET_COURSE]: (state = initialState, action) => {
      return {
        ...state,
        selectedCourse: action.payload
      }
    }
  });

  return reducer;

});

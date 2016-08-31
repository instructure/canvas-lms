define([
  'redux-actions',
], (ReduxActions) => {

  const { createAction } = ReduxActions;

  const keys = {
    SET_FIND_APPOINTMENT_MODE: 'SET_FIND_APPOINTMENT_MODE',
    SET_COURSE: 'SET_COURSE'
  }

  const actions = {
    setFindAppointmentMode: createAction(keys.SET_FIND_APPOINTMENT_MODE),
    setCourse: createAction(keys.SET_COURSE)
  };

  return {
    actions,
    keys
  };

});

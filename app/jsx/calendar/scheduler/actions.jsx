define([
  'redux-actions',
], (ReduxActions) => {

  const { createAction } = ReduxActions;

  const keys = {
    SET_FIND_APPOINTMENT_MODE: 'SET_FIND_APPOINTMENT_MODE'
  }

  const actions = {
    setFindAppointmentMode: createAction(keys.SET_FIND_APPOINTMENT_MODE)
  };

  return {
    actions,
    keys
  };

});

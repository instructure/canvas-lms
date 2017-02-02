import { createAction } from 'redux-actions'

  const keys = {
    SET_FIND_APPOINTMENT_MODE: 'SET_FIND_APPOINTMENT_MODE',
    SET_COURSE: 'SET_COURSE'
  }

  const actions = {
    setFindAppointmentMode: createAction(keys.SET_FIND_APPOINTMENT_MODE),
    setCourse: createAction(keys.SET_COURSE)
  };

export default {
    actions,
    keys
  };

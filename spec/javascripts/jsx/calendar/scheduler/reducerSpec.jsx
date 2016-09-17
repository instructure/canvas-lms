define([
  'jsx/calendar/scheduler/reducer'
], (reducer) => {

  module('Scheduler Reducer');

  test('sets inFindAppointmentMode on SET_FIND_APPOINTMENT_MODE', () => {

    const initialState = {
      inFindAppointmentMode: false
    };

    const newState = reducer(initialState, {
      type: 'SET_FIND_APPOINTMENT_MODE',
      payload: true
    });

    ok(newState.inFindAppointmentMode)
  });

});

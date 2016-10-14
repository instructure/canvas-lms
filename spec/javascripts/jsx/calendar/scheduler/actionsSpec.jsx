define([
  'jsx/calendar/scheduler/actions',
], (Actions) => {

  module('Scheduler Actions');

  test('setFindAppointmentMode returns the proper action', () => {
    const actual = Actions.actions.setFindAppointmentMode(true);
    const expected = {
      type: 'SET_FIND_APPOINTMENT_MODE',
      payload: true
    };

    deepEqual(actual, expected);
  })

  test('setCourse returns the proper action', () => {
    const actual = Actions.actions.setCourse({id: 4, name:'blah'});
    const expected = {
      type: 'SET_COURSE',
      payload: {id: 4, name:'blah'}
    };

    deepEqual(actual, expected)
  })

})

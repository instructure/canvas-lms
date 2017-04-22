define([
  'jsx/calendar/scheduler/reducer'
], (reducer) => {

  QUnit.module('Scheduler Reducer');

  test('sets inFindAppointmentMode on SET_FIND_APPOINTMENT_MODE', () => {

    const initialState = {
      inFindAppointmentMode: false,
      setCourse: {}
    }

    const newState = reducer(initialState, {
      type: 'SET_FIND_APPOINTMENT_MODE',
      payload: true
    })

    ok(newState.inFindAppointmentMode)
  })

  test('sets selectedCourse on SET_COURSE', () => {

    const initialState = {
      inFindAppointmentMode: false,
      selectedCourse : null
    }

    const newState = reducer(initialState, {
      type: 'SET_COURSE',
      payload: {id: 1, name: "blah"}
    })

    ok(newState.selectedCourse)
  })
})

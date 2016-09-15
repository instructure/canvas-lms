define([
  'compiled/calendar/CommonEvent.CalendarEvent',
], (CalendarEvent) => {

  let calendarEvent;

  module('CommonEvent.CalendarEvent', {
    setup () {
      const data = {}
      const contexts = ['course_1']
      calendarEvent = new CalendarEvent(data, contexts)
    },
    teardown () {
      calendarEvent = null;
    }
  });

  test('calculateAppointmentGroupEventStatus returns number of available slots string when more than 0', () => {
    calendarEvent.calendarEvent.available_slots = 20;
    equal(calendarEvent.calculateAppointmentGroupEventStatus(), '20 Available');
  });

  test('calculateAppointmentGroupEventStatus gives "Filled" string when 0 available_slots', () => {
    calendarEvent.calendarEvent.available_slots = 0;
    equal(calendarEvent.calculateAppointmentGroupEventStatus(), 'Filled');
  });

  test('calculateAppointmentGroupEventStatus gives "Reserved" string when reserved', () => {
    calendarEvent.calendarEvent.reserved = true;
    equal(calendarEvent.calculateAppointmentGroupEventStatus(), 'Reserved');
  });

  test('calculateAppointmentGroupEventStatus gives "Reserved" string when there is an appointment_group_url and parent_event_id', () => {
    calendarEvent.calendarEvent.reserved = false;
    calendarEvent.calendarEvent.appointment_group_url = 1;
    calendarEvent.calendarEvent.parent_event_id = 30;
    equal(calendarEvent.calculateAppointmentGroupEventStatus(), 'Reserved');
  });


})

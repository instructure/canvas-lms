define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/calendar/scheduler/components/appointment_groups/AppointmentGroupList',
], (React, ReactDOM, TestUtils, AppointmentGroupList) => {
  module('AppointmentGroupList')

  test('renders the AppointmentGroupList component', () => {
    const appointmentGroup = { appointments: [{ child_events: [{ user: { sortable_name: 'test' } }], start_at: '2016-10-18T19:00:00Z', end_at: '2016-10-18T110:00:00Z' }], appointments_count: 1 }

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup} />)
    const appointmentGroupList = TestUtils.findRenderedDOMComponentWithClass(component, 'AppointmentGroupList__List')
    ok(appointmentGroupList)
  })

  test('renders renders reserved badge when someone is signed up in a slot', () => {
    const appointmentGroup = {
      appointments: [{
        child_events: [{
          user: { sortable_name: test }
        }],
        start_at: '2016-10-18T19:00:00Z',
        end_at: '2016-10-18T110:00:00Z'
      }, {
        child_events: [],
        start_at: '2016-10-18T16:00:00Z',
        end_at: '2016-10-18T17:00:00Z'
      }],
      appointments_count: 2
    }

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup} />)
    const reservedBadge = TestUtils.scryRenderedDOMComponentsWithClass(component, 'AppointmentGroupList__Badge--reserved')[0]
    ok(reservedBadge)
  })

  test('renders available badge when no one is signed up', () => {
    const appointmentGroup = {
      appointments: [{
        child_events: [],
        start_at: '2016-10-18T19:00:00Z',
        end_at: '2016-10-18T110:00:00Z'
      }, {
        child_events: [],
        start_at: '2016-10-18T16:00:00Z',
        end_at: '2016-10-18T17:00:00Z'
      }],
      appointments_count: 2
    }

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup} />)
    const availableBadge = TestUtils.scryRenderedDOMComponentsWithClass(component, 'AppointmentGroupList__Badge--unreserved')[0]
    ok(availableBadge)
  })

  test('renders correct user names', () => {
    const appointmentGroup = {
      appointments: [{
        child_events: [{
          user: { sortable_name: 'test1' }
        }],
        start_at: '2016-10-18T19:00:00Z',
        end_at: '2016-10-18T110:00:00Z'
      }, {
        child_events: [{
          user: { sortable_name: 'test2' }
        }],
        start_at: '2016-10-18T16:00:00Z',
        end_at: '2016-10-18T17:00:00Z'
      }],
      appointments_count: 2,
      participants_per_appointment: 1
    }

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup} />)
    const appointmentGroupNames = TestUtils.scryRenderedDOMComponentsWithClass(component, 'AppointmentGroupList__Appointment-label')
    equal(appointmentGroupNames.length, 2)
    equal(appointmentGroupNames[0].textContent, 'test1')
    equal(appointmentGroupNames[1].textContent, 'test2')
  })

  test('renders "Available" at the end of the user list if more appointments are available for the slot', () => {
    const appointmentGroup = {
      appointments: [{
        child_events: [{
          user: { sortable_name: 'test1' }
        }],
        start_at: '2016-10-18T19:00:00Z',
        end_at: '2016-10-18T110:00:00Z',
        child_events_count: 1
      }, {
        child_events: [{
          user: { sortable_name: 'test2' }
        }, {
          user: { sortable_name: 'test3' }
        }],
        start_at: '2016-10-18T16:00:00Z',
        end_at: '2016-10-18T17:00:00Z',
        child_events_count: 2
      }],
      appointments_count: 2,
      participants_per_appointment: 2
    }

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup} />)
    const appointmentGroupNames = TestUtils.scryRenderedDOMComponentsWithClass(component, 'AppointmentGroupList__Appointment-label')
    equal(appointmentGroupNames.length, 2)
    equal(appointmentGroupNames[0].textContent, 'test1; Available')
    equal(appointmentGroupNames[1].textContent, 'test2; test3')
  })


})

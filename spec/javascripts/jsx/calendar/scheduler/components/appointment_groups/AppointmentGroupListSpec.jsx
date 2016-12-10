define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/calendar/scheduler/components/appointment_groups/AppointmentGroupList',
], (React, ReactDOM, TestUtils, AppointmentGroupList) => {
  module('AppointmentGroupList')

  test('renders the AppointmentGroupList component', () => {
    const appointmentGroup = {"appointments": [{"child_events": [{"user": {"sortable_name": "test"}}], "start_at": "2016-10-18T19:00:00Z", "end_at": "2016-10-18T110:00:00Z"}], "appointments_count": 1}

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup}/>)
    const appointmentGroupList = TestUtils.findRenderedDOMComponentWithClass(component, 'AppointmentGroupList__List')
    ok(appointmentGroupList)
  })

  test('renders unreserved with user', () => {
    const appointmentGroup = {"appointments": [{"child_events": [{"user": {"sortable_name": "test"}}], "start_at": "2016-10-18T19:00:00Z", "end_at": "2016-10-18T110:00:00Z"}], "appointments_count": 1}
    const expectedContent = "7pm to 12am - test; Available"

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup}/>)
    const appointmentGroupUnreserved = TestUtils.findRenderedDOMComponentWithClass(component, 'AppointmentGroupList__unreserved')
    ok(expectedContent === appointmentGroupUnreserved.textContent)
  })

  test('renders multiple unreserved with user', () => {
    const appointmentGroup = {"appointments": [{"child_events": [{"user": {"sortable_name": "test"}}], "start_at": "2016-10-18T19:00:00Z", "end_at": "2016-10-18T110:00:00Z"}, {"child_events": [{"user": {"sortable_name": "test"}}], "start_at": "2016-10-18T16:00:00Z", "end_at": "2016-10-18T17:00:00Z"}], "appointments_count": 2}

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup}/>)
    const appointmentGroupUnreserved = TestUtils.findRenderedDOMComponentWithClass(component, 'AppointmentGroupList__List')
    ok(appointmentGroupUnreserved.childElementCount === 2)
  })

  test('renders reserved with user', () => {
    const appointmentGroup = {"appointments": [{"child_events": [{"user": {"sortable_name": "test"}}], "start_at": "2016-10-18T19:00:00Z", "end_at": "2016-10-18T110:00:00Z", 'reserved': true}, {"child_events": [{"user": {"sortable_name": "test"}}], "start_at": "2016-10-18T16:00:00Z", "end_at": "2016-10-18T17:00:00Z"}], "appointments_count": 2}

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup}/>)
    const appointmentGroupReserved = TestUtils.findRenderedDOMComponentWithClass(component, 'AppointmentGroupList__reserved')
    ok(appointmentGroupReserved)
  })

  test('renders correct user names', () => {
    const appointmentGroup = {"appointments": [{"child_events": [{"user": {"sortable_name": "test1"}}], "start_at": "2016-10-18T19:00:00Z", "end_at": "2016-10-18T110:00:00Z"}, {"child_events": [{"user": {"sortable_name": "test2"}}], "start_at": "2016-10-18T16:00:00Z", "end_at": "2016-10-18T17:00:00Z"}], "appointments_count": 2, participants_per_appointment: 1}

    const component = TestUtils.renderIntoDocument(<AppointmentGroupList appointmentGroup={appointmentGroup}/>)
    const appointmentGroupNames = TestUtils.scryRenderedDOMComponentsWithClass(component, 'AppointmentGroupList__Appointment-label').map(nameComp => ReactDOM.findDOMNode(nameComp))
    equal(appointmentGroupNames.length, 2)
    equal(appointmentGroupNames[0].textContent.split(' - ')[1], 'test1')
    equal(appointmentGroupNames[1].textContent.split(' - ')[1], 'test2')
  })
})

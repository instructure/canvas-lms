define([
  'react',
  'jsx/calendar/scheduler/components/appointment_groups/AppointmentGroupList',
], (React, AppointmentGroupList) => {
  const TestUtils = React.addons.TestUtils

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
})

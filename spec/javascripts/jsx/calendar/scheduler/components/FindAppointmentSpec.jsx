define([
  'react',
  'jsx/calendar/scheduler/components/FindAppointment',
  'react-dom',
  'react-modal'
], (react, FindAppointmentApp, ReactDom, Modal) => {
  const TestUtils = React.addons.TestUtils

  module('FindAppointmentApp')

  test('renders the FindAppoint component', () => {
    let courses = [
      {name: "testCourse1", asset_string: "thing1"},
      {name: "testCourse2", asset_string: "thing2"},
    ]


    let component = TestUtils.renderIntoDocument(<FindAppointmentApp courses={courses} />)
    let findAppointmentAppButton = TestUtils.findRenderedDOMComponentWithClass(component, 'Button')
    equal(findAppointmentAppButton.textContent, "Find Appointment")
  });
});

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

    const store = {
      getState () {
         return {
            inFindAppointmentMode: false
         }
      }
    }


    let component = TestUtils.renderIntoDocument(<FindAppointmentApp courses={courses} store={store}/>)
    let findAppointmentAppButton = TestUtils.findRenderedDOMComponentWithClass(component, 'Button')
    equal(findAppointmentAppButton.textContent, "Find Appointment")
  })

  test('correct button renders', () => {
    let courses = [
      {name: "testCourse1", asset_string: "thing1"},
      {name: "testCourse2", asset_string: "thing2"},
    ]

    const store = {
      getState () {
         return {
            inFindAppointmentMode: true
         }
      }
    }


    let component = TestUtils.renderIntoDocument(<FindAppointmentApp store={store} courses={courses} />)
    let findAppointmentAppButton = TestUtils.findRenderedDOMComponentWithClass(component, 'Button')
    equal(findAppointmentAppButton.textContent, "Close")
  })
})

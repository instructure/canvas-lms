define([
  'react',
  'react-addons-test-utils',
  'enzyme',
  'jsx/calendar/scheduler/components/FindAppointment'
], (React, TestUtils, Enzyme, FindAppointmentApp) => {
  module('FindAppointmentApp')

  test('renders the FindAppoint component', () => {
    const courses = [
      { name: 'testCourse1', asset_string: 'thing1' },
      { name: 'testCourse2', asset_string: 'thing2' },
    ]

    const store = {
      getState () {
        return {
          inFindAppointmentMode: false
        }
      }
    }


    const component = TestUtils.renderIntoDocument(<FindAppointmentApp courses={courses} store={store} />)
    const findAppointmentAppButton = TestUtils.findRenderedDOMComponentWithClass(component, 'Button')
    equal(findAppointmentAppButton.textContent, 'Find Appointment')
  })

  test('correct button renders', () => {
    const courses = [
      { name: 'testCourse1', asset_string: 'thing1' },
      { name: 'testCourse2', asset_string: 'thing2' },
    ]

    const store = {
      getState () {
        return {
          inFindAppointmentMode: true
        }
      }
    }


    const component = TestUtils.renderIntoDocument(<FindAppointmentApp store={store} courses={courses} />)
    const findAppointmentAppButton = TestUtils.findRenderedDOMComponentWithClass(component, 'Button')
    equal(findAppointmentAppButton.textContent, 'Close')
  })

  test('selectCourse sets the proper selected course', () => {
    const { mount } = Enzyme
    const courses = [
      { id: 1, name: 'testCourse1', asset_string: 'thing1' },
      { id: 2, name: 'testCourse2', asset_string: 'thing2' },
    ]

    const store = {
      getState () {
        return {
          inFindAppointmentMode: false
        }
      }
    }

    const fakeEvent = {
      target: {
        value: 2
      }
    }

    const wrapper = mount(<FindAppointmentApp courses={courses} store={store} />);
    const instance = wrapper.component.getInstance()
    instance.selectCourse(fakeEvent);
    deepEqual(wrapper.state('selectedCourse'), courses[1])
  })
})

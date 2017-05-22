/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'react',
  'react-addons-test-utils',
  'enzyme',
  'jsx/calendar/scheduler/components/FindAppointment'
], (React, TestUtils, Enzyme, FindAppointmentApp) => {
  QUnit.module('FindAppointmentApp')

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

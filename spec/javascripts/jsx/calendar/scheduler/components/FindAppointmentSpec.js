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

import React from 'react'
import {shallow, mount} from 'enzyme'
import FindAppointmentApp from 'ui/features/calendar/react/scheduler/components/FindAppointment'

QUnit.module('FindAppointmentApp')

test('renders the FindAppoint component', () => {
  const courses = [
    {name: 'testCourse1', asset_string: 'thing1'},
    {name: 'testCourse2', asset_string: 'thing2'},
  ]

  const store = {
    getState() {
      return {
        inFindAppointmentMode: false,
      }
    },
  }

  const wrapper = shallow(<FindAppointmentApp courses={courses} store={store} />)
  equal(wrapper.find('#FindAppointmentButton').text(), 'Find Appointment')
})

test('correct button renders', () => {
  const courses = [
    {name: 'testCourse1', asset_string: 'thing1'},
    {name: 'testCourse2', asset_string: 'thing2'},
  ]

  const store = {
    getState() {
      return {
        inFindAppointmentMode: true,
      }
    },
  }

  const wrapper = shallow(<FindAppointmentApp courses={courses} store={store} />)
  equal(wrapper.find('#FindAppointmentButton').text(), 'Close')
})

test('selectCourse sets the proper selected course', () => {
  const courses = [
    {id: 1, name: 'testCourse1', asset_string: 'thing1'},
    {id: 2, name: 'testCourse2', asset_string: 'thing2'},
  ]

  const store = {
    getState() {
      return {
        inFindAppointmentMode: false,
      }
    },
  }

  const wrapper = mount(<FindAppointmentApp courses={courses} store={store} />)
  wrapper.instance().selectCourse(2)
  deepEqual(wrapper.state('selectedCourse'), courses[1])
})

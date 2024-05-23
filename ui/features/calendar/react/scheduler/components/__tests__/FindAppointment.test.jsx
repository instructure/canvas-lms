/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import {render} from '@testing-library/react'
import FindAppointmentApp from '../FindAppointment'

const courses = [
  {id: 1, name: 'testCourse1', asset_string: 'thing1'},
  {id: 2, name: 'testCourse2', asset_string: 'thing2'},
]
describe('FindAppointmentApp', () => {
  test('renders the FindAppoint component', () => {
    const store = {
      getState() {
        return {
          inFindAppointmentMode: false,
        }
      },
    }

    const wrapper = shallow(<FindAppointmentApp courses={courses} store={store} />)
    expect(wrapper.find('#FindAppointmentButton').text()).toEqual('Find Appointment')
  })

  test('correct button renders', () => {
    const store = {
      getState() {
        return {
          inFindAppointmentMode: true,
        }
      },
    }

    const wrapper = shallow(<FindAppointmentApp courses={courses} store={store} />)
    expect(wrapper.find('#FindAppointmentButton').text()).toEqual('Close')
  })

  test('selectCourse sets the proper selected course', () => {
    const store = {
      getState() {
        return {
          inFindAppointmentMode: false,
        }
      },
    }

    const ref = React.createRef()
    render(<FindAppointmentApp courses={courses} store={store} ref={ref} />)
    ref.current.selectCourse(2)
    expect(ref.current.state.selectedCourse).toEqual(courses[1])
  })
})

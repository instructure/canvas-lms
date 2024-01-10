/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import moment from 'moment-timezone'
import CalendarEventModal from '../index'
import {convertApiUserContent} from '../../../utilities/contentUtils'

jest.mock('../../../utilities/contentUtils')
convertApiUserContent.mockImplementation(p => p)

function defaultProps(options = {}) {
  const currentUser = options.currentUser || {}
  delete options.currentUser
  return {
    open: true,
    requestClose: jest.fn(),
    title: 'event title',
    html_url: 'http://example.com',
    courseName: 'the course',
    currentUser: {
      id: '1234',
      displayName: 'me',
      avatarUrl: 'http://example.com',
      color: '#777777',
      ...currentUser,
    },
    location: 'somewhere',
    address: 'here, specifically',
    details: 'about this event',
    startTime: moment.tz('2018-09-27T13:00:00', 'Asia/Tokyo'),
    endTime: moment.tz('2018-09-27T14:00:00', 'Asia/Tokyo'),
    allDay: false,
    timeZone: 'Asia/Tokyo',
    ...options,
  }
}

it('renders', () => {
  const wrapper = shallow(<CalendarEventModal {...defaultProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders with only the startTime', () => {
  const wrapper = shallow(<CalendarEventModal {...defaultProps({endTime: null})} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders with allDay', () => {
  const wrapper = shallow(<CalendarEventModal {...defaultProps({allDay: true})} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders with user displayName for calendar', () => {
  const wrapper = shallow(<CalendarEventModal {...defaultProps({courseName: null})} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders without location', () => {
  const wrapper = shallow(<CalendarEventModal {...defaultProps({location: null})} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders without address', () => {
  const wrapper = shallow(<CalendarEventModal {...defaultProps({address: null})} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders without details', () => {
  const wrapper = shallow(<CalendarEventModal {...defaultProps({details: null})} />)
  expect(wrapper).toMatchSnapshot()
})

it('converts the details with convertApiUserContent', () => {
  const props = defaultProps()
  shallow(<CalendarEventModal {...props} />)
  expect(convertApiUserContent).toHaveBeenCalledWith(props.details)
})

/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Opportunities_ as Opportunities, OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID} from '../index'

function defaultProps() {
  return {
    newOpportunities: [
      {
        id: '1',
        course_id: '1',
        due_at: '2017-03-09T20:40:35Z',
        html_url: 'http://www.non_default_url.com',
        name: 'learning object title',
      },
    ],
    dismissedOpportunities: [
      {
        id: '2',
        course_id: '1',
        due_at: '2017-03109T20:40:35Z',
        html_url: 'http://www.non_default_url.com',
        name: 'another learning object title',
        plannerOverride: {dismissed: true},
      },
    ],
    courses: [{id: '1', shortName: 'Course Short Name'}],
    timeZone: 'America/Denver',
    dismiss: () => {},
    id: '6',
    togglePopover: () => {},
  }
}

jest.useFakeTimers()

it('renders the base component correctly with one of each kind of opportunity', () => {
  const wrapper = shallow(<Opportunities {...defaultProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders the right course with the right opportunity', () => {
  const tempProps = defaultProps()
  tempProps.newOpportunities = tempProps.newOpportunities.concat({
    id: '2',
    course_id: '2',
    html_url: 'http://www.non_default_url.com',
    due_at: '2017-03-09T20:40:35Z',
    name: 'other learning object',
  })
  tempProps.courses = tempProps.courses.concat({
    id: '2',
    shortName: 'A different Course Name',
  })
  const wrapper = shallow(<Opportunities {...tempProps} />)
  expect(wrapper).toMatchSnapshot()
})

it('renders nothing if no opportunities', () => {
  const tempProps = defaultProps()
  tempProps.newOpportunities = []
  tempProps.dismissedOpportunities = []
  const wrapper = shallow(<Opportunities {...tempProps} />)
  expect(wrapper).toMatchSnapshot()
})

it('calls toggle popover when escape is pressed', () => {
  const tempProps = defaultProps()
  const mockDispatch = jest.fn()
  tempProps.togglePopover = mockDispatch
  const wrapper = shallow(<Opportunities {...tempProps} />)
  wrapper.find('#opportunities_parent').simulate('keyDown', {
    keyCode: 27,
    which: 27,
    key: 'escape',
    preventDefault: () => {},
  })
  expect(tempProps.togglePopover).toHaveBeenCalled()
})

it('registers itself as animatable', () => {
  const fakeRegister = jest.fn()
  const fakeDeregister = jest.fn()
  const wrapper = mount(
    <Opportunities
      {...defaultProps()}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
    />
  )
  const instance = wrapper.instance()
  expect(fakeRegister).toHaveBeenCalledWith('opportunity', instance, -1, [
    OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID,
  ])
  wrapper.unmount()
  expect(fakeDeregister).toHaveBeenCalledWith('opportunity', instance, [
    OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID,
  ])
})

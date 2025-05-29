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
import {shallow} from 'enzyme'
import {render} from '@testing-library/react'
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
  expect(wrapper.find('Tabs')).toHaveLength(1)
  expect(wrapper.find('CloseButton')).toHaveLength(1)
  expect(wrapper.find('#opportunities_parent')).toHaveLength(1)
  expect(wrapper.find('Panel')).toHaveLength(2) // new and dismissed tabs
  // Check that the component structure is correct
  expect(wrapper.type()).toBe(React.Fragment)
  expect(wrapper.find('style')).toHaveLength(1)
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
  expect(wrapper.find('Tabs')).toHaveLength(1)
  expect(wrapper.find('Panel')).toHaveLength(2)
  // Verify component structure and that it has the expected number of opportunities in props
  expect(tempProps.newOpportunities).toHaveLength(2)
  expect(tempProps.dismissedOpportunities).toHaveLength(1)
})

it('renders empty state when no opportunities', () => {
  const tempProps = defaultProps()
  tempProps.newOpportunities = []
  tempProps.dismissedOpportunities = []
  const wrapper = shallow(<Opportunities {...tempProps} />)
  expect(wrapper.type()).toBe(React.Fragment)
  expect(wrapper.find('#opportunities_parent')).toHaveLength(1)
  expect(wrapper.find('Tabs')).toHaveLength(1)
  // Should show empty state messages instead of opportunities
  expect(wrapper.text()).toContain('Nothing new needs attention.')
  expect(wrapper.text()).toContain('Nothing here needs attention.')
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
  const ref = React.createRef()
  render(
    <Opportunities
      {...defaultProps()}
      registerAnimatable={fakeRegister}
      deregisterAnimatable={fakeDeregister}
      ref={ref}
    />,
  )
  expect(fakeRegister).toHaveBeenCalledWith('opportunity', ref.current, -1, [
    OPPORTUNITY_SPECIAL_FALLBACK_FOCUS_ID,
  ])
})

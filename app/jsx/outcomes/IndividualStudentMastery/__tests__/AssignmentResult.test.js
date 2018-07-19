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
import { render, shallow } from 'enzyme'
import AssignmentResult from '../AssignmentResult'

const defaultProps = (props = {}) => (
  Object.assign({
    outcome: {
      id: 1,
      mastered: false,
      calculation_method: 'highest',
      ratings: [
        { description: 'My first rating' },
        { description: 'My second rating' }
      ],
      results: [],
      title: 'foo',
      mastery_points: 3,
      points_possible: 5
    },
    result: {
      id: 1,
      score: 1,
      percent: 0.1,
      assignment: {
        id: 1,
        html_url: 'http://foo',
        name: 'My assignment',
        submission_types: 'online_quiz'
      }
    }
  }, props)
)

it('renders the AlignmentResult component', () => {
  const wrapper = shallow(<AssignmentResult {...defaultProps()}/>)
  expect(wrapper.debug()).toMatchSnapshot()
})

it('includes the assignment name', () => {
  const wrapper = render(<AssignmentResult {...defaultProps()}/>)
  expect(wrapper.text()).toMatch('My assignment')
})

it('includes the ratings of the outcome', () => {
  const wrapper = render(<AssignmentResult {...defaultProps()}/>)
  expect(wrapper.text()).toMatch('My second rating')
})

it('shows scores when points are not hidden', () => {
  const wrapper = render(<AssignmentResult {...defaultProps()}/>)
  expect(wrapper.text()).toMatch('Your score: 1')
})

it('does not show scores when points are hidden', () => {
  const props = defaultProps()
  props.result.hide_points = true
  const wrapper = render(<AssignmentResult {...props}/>)
  expect(wrapper.text()).toMatch('Your score')
  expect(wrapper.text()).not.toMatch('Your score: 1')
})

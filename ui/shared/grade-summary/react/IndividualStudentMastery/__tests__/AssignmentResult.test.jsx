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
import {render} from '@testing-library/react'
import AssignmentResult from '../AssignmentResult'

const defaultProps = (props = {}) => ({
  outcome: {
    id: 1,
    mastered: false,
    calculation_method: 'highest',
    ratings: [{description: 'My first rating'}, {description: 'My second rating'}],
    results: [],
    title: 'foo',
    mastery_points: 3,
    points_possible: 5,
  },
  result: {
    id: 1,
    score: 2,
    percent: 0.2,
    assignment: {
      id: 1,
      html_url: 'http://foo',
      name: 'My assignment',
      submission_types: 'online_quiz',
    },
  },
  ...props,
})

it('renders the AlignmentResult component', () => {
  const wrapper = shallow(<AssignmentResult {...defaultProps()} />)
  expect(wrapper).toMatchSnapshot()
})

it('includes the assignment name', () => {
  const wrapper = render(<AssignmentResult {...defaultProps()} />)
  expect(wrapper.getByRole('link')).toHaveTextContent('My assignment')
})

it('includes the ratings of the outcome', () => {
  const wrapper = render(<AssignmentResult {...defaultProps()} />)
  expect(wrapper.getByText('My second rating')).toBeInTheDocument()
})

it('shows scores when points are not hidden', () => {
  const wrapper = render(<AssignmentResult {...defaultProps()} />)
  expect(wrapper.getByText('Your score: 1')).toBeInTheDocument()
})

it('does not show scores when points are hidden', () => {
  const props = defaultProps()
  props.result.hide_points = true
  const wrapper = render(<AssignmentResult {...props} />)
  expect(wrapper.queryByText('Your score')).toBeInTheDocument()
  expect(wrapper.queryByText('Your score: 1')).toBeNull()
})

describe('with percent not available', () => {
  it('can use the raw score, result.points_possible, and outcome.points_possible', () => {
    const props = defaultProps()
    props.result.percent = null
    props.result.points_possible = 5
    const wrapper = render(<AssignmentResult {...props} />)
    expect(wrapper.queryByText('Your score: 2')).toBeInTheDocument()
  })

  it('can use the raw score, result.points_possible, and outcome.mastery_points if outcome.points_possible is 0', () => {
    const props = defaultProps()
    props.result.percent = null
    props.result.points_possible = 5
    props.outcome.points_possible = 0
    const wrapper = render(<AssignmentResult {...props} />)
    expect(wrapper.queryByText('Your score: 1.2')).toBeInTheDocument()
  })

  it('falls back to using raw score if percent and result.points_possible is not available', () => {
    const props = defaultProps()
    props.result.percent = null
    const wrapper = render(<AssignmentResult {...props} />)
    expect(wrapper.queryByText('Your score: 2')).toBeInTheDocument()
  })
})

it('falls back to using mastery points if points possible is 0', () => {
  const props = defaultProps()
  props.outcome = {
    id: 1,
    mastered: false,
    calculation_method: 'highest',
    ratings: [{description: 'My first rating'}, {description: 'My second rating'}],
    results: [],
    title: 'foo',
    mastery_points: 3,
    points_possible: 0,
  }
  const wrapper = render(<AssignmentResult {...props} />)
  expect(wrapper.queryByText('Your score: 0.6')).toBeInTheDocument()
})

it('correctly rounds to two decimal places', () => {
  const props = defaultProps()
  props.result.percent = 0.257
  const wrapper = render(<AssignmentResult {...props} />)
  expect(wrapper.queryByText('Your score: 1.29')).toBeInTheDocument()
})

it('renders unlinked result', () => {
  const props = defaultProps()
  props.result.assignment.html_url = ''
  const wrapper = render(<AssignmentResult {...props} />)
  expect(wrapper.container.querySelector(`svg[name="IconHighlighter"]`)).toBeInTheDocument()
})

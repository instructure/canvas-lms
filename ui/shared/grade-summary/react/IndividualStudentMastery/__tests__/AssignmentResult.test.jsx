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

it('renders the AlignmentResult component with correct structure', () => {
  const wrapper = shallow(<AssignmentResult {...defaultProps()} />)

  // Should render main Flex container with column layout
  const mainFlex = wrapper.find('Flex')
  expect(mainFlex).toHaveLength(1)
  expect(mainFlex.prop('direction')).toBe('column')
  expect(mainFlex.prop('padding')).toBe('small')

  // Should have three main sections (assignment link, score, ratings)
  const items = wrapper.find('Item')
  expect(items).toHaveLength(3)

  // First item should contain assignment link
  const linkItem = items.at(0)
  const link = linkItem.find('Link')
  expect(link).toHaveLength(1)
  expect(link.prop('href')).toBe('http://foo')
  expect(link.children().text()).toBe('My assignment')

  // Second item should contain score display
  const scoreItem = items.at(1)
  const scoreText = scoreItem.find('Text')
  expect(scoreText).toHaveLength(1)
  expect(scoreText.prop('fontStyle')).toBe('italic')
  expect(scoreText.prop('weight')).toBe('bold')

  // Third item should contain ratings component
  const ratingsItem = items.at(2)
  const ratings = ratingsItem.find('Ratings')
  expect(ratings).toHaveLength(1)
  expect(ratings.prop('points')).toBe(1)
  expect(ratings.prop('pointsPossible')).toBe(5)
  expect(ratings.prop('tiers')).toEqual([
    {description: 'My first rating'},
    {description: 'My second rating'},
  ])
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

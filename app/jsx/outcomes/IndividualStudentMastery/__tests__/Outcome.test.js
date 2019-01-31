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
import Outcome from '../Outcome'

const result = (id = 1, date = new Date(), hidePoints = false) => ({
  id,
  percent: 0.1,
  assignment: {
    id: 'assignment_1',
    html_url: 'http://foo',
    name: 'My alignment',
    submission_types: '',
    score: 0
  },
  hide_points: hidePoints,
  submitted_or_assessed_at: date.toISOString()
})

const defaultProps = (props = {}) => (
  Object.assign({
    outcome: {
      id: 1,
      assignments: [{
        assignment_id: 1,
        learning_outcome_id: 1,
        submission_types: "online_quiz",
        title: "My assignment",
        url: "www.example.com"
      }],
      expansionId: 100,
      mastered: false,
      mastery_points: 3,
      points_possible: 5,
      calculation_method: 'highest',
      ratings: [
        { description: 'My first rating' },
        { description: 'My second rating' }
      ],
      results: [
        {
          id: 1,
          score: 1,
          percent: 0.1,
          assignment: {
            id: 'assignment_1',
            html_url: 'http://foo',
            name: 'My assignment',
            submission_types: 'online_quiz',
            score: 0
          }
        }
      ],
      title: 'My outcome',
      score: 1
    },
    expanded: false,
    onExpansionChange: () => {},
  }, props)
)

it('renders the Outcome component', () => {
  const wrapper = shallow(<Outcome {...defaultProps()}/>)
  expect(wrapper).toMatchSnapshot()
})

it('renders correctly expanded', () => {
  const wrapper = shallow(<Outcome {...defaultProps()} expanded />)
  expect(wrapper).toMatchSnapshot()
})

it('renders correctly expanded with no results', () => {
  const props = defaultProps()
  props.outcome.results = []
  const wrapper = shallow(<Outcome {...props} expanded />)
  expect(wrapper).toMatchSnapshot()
})

it('renders correctly expanded with no results or assignments', () => {
  const props = defaultProps()
  props.outcome.results = []
  props.outcome.assignments = []
  const wrapper = shallow(<Outcome {...props} expanded />)
  expect(wrapper).toMatchSnapshot()
})

describe('header', () => {
  it('includes the outcome name', () => {
    const wrapper = shallow(<Outcome {...defaultProps()}/>)
    const header = wrapper.find('ToggleGroup')
    const summary = render(header.prop('summary'))
    expect(summary.text()).toMatch('My outcome')
  })

  it('includes mastery when mastered', () => {
    const props = defaultProps()
    props.outcome.mastered = true
    const wrapper = shallow(<Outcome {...props} />)
    const header = wrapper.find('ToggleGroup')
    const summary = render(header.prop('summary'))
    expect(summary.text()).toMatch('Mastered')
  })

  it('includes non-mastery when not mastered', () => {
    const wrapper = shallow(<Outcome {...defaultProps()} />)
    const header = wrapper.find('ToggleGroup')
    const summary = render(header.prop('summary'))
    expect(summary.text()).toMatch('Not mastered')
  })

  it('shows correct number of alignments', () => {
    const wrapper = shallow(<Outcome {...defaultProps()} />)
    const header = wrapper.find('ToggleGroup')
    const summary = render(header.prop('summary'))
    expect(summary.text()).toMatch('1 alignment')
  })

  it('shows points if only some results have hide points enabled', () => {
    const props = defaultProps()
    props.outcome.results = [result(1, undefined, false), result(2, undefined, true)]
    const wrapper = shallow(<Outcome {...props}/>)
    const header = wrapper.find('ToggleGroup')
    const summary = render(header.prop('summary'))
    expect(summary.text()).toMatch('1/5')
  })

  it('does not show points if all results have hide points enabled', () => {
    const props = defaultProps()
    props.outcome.results = [result(1, undefined, true), result(2, undefined, true)]
    const wrapper = shallow(<Outcome {...props}/>)
    const header = wrapper.find('ToggleGroup')
    const summary = render(header.prop('summary'))
    expect(summary.text()).not.toMatch('1/5')
  })
})

it('includes the individual results', () => {
  const wrapper = shallow(<Outcome {...defaultProps()} />)
  expect(wrapper.find('AssignmentResult')).toHaveLength(1)
})

it('renders the results by most recent', () => {
  const props = defaultProps()
  const now = new Date()
  const minuteAgo = new Date(now - 60000)
  const hourAgo = new Date(now - 3600000)
  const yearishAgo = new Date(now - 3600000 * 24 * 360)
  props.outcome.results = [
    result(1, hourAgo),
    result(2, now),
    result(3, minuteAgo),
    result(4, yearishAgo)
  ]

  const wrapper = shallow(<Outcome {...props} />)
  const results = wrapper.find('AssignmentResult')
  expect(results).toHaveLength(4)
  expect(results.get(0).props.result.id).toEqual(2) // now
  expect(results.get(1).props.result.id).toEqual(3) // minuteAgo
  expect(results.get(2).props.result.id).toEqual(1) // hourAgo
  expect(results.get(3).props.result.id).toEqual(4) // yearishAgo
})

describe('handleToggle()', () => {
  it('calls onExpansionChange with the correct data', () => {
    const props = defaultProps()
    props.onExpansionChange = jest.fn()

    const wrapper = shallow(<Outcome {...props} />)
    wrapper.instance().handleToggle(null, true)
    expect(props.onExpansionChange).toBeCalledWith('outcome', 100, true)
  })
})

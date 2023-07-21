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
import {render, fireEvent, within} from '@testing-library/react'
import Outcome from '../Outcome'

const result = ({id = 1, date = new Date(), hide_points = false}, assignmentOverrides = {}) => ({
  id,
  percent: 0.1,
  assignment: {
    id: 'assignment_1',
    html_url: 'http://foo',
    name: 'My alignment',
    submission_types: '',
    score: 0,
    ...assignmentOverrides,
  },
  hide_points,
  submitted_or_assessed_at: date.toISOString(),
})

const time1 = new Date(Date.UTC(2018, 1, 1, 7, 1, 0)).toISOString()
const time2 = new Date(Date.UTC(2019, 1, 1, 7, 1, 0)).toISOString()

const defaultProps = (props = {}) => ({
  outcome: {
    id: 1,
    assignments: [
      {
        assignment_id: '1',
        learning_outcome_id: 1,
        submission_types: 'online_quiz',
        name: 'My assignment',
        html_url: 'www.example.com',
      },
    ],
    expansionId: 100,
    mastered: false,
    mastery_points: 3,
    points_possible: 5,
    calculation_method: 'highest',
    ratings: [{description: 'My first rating'}, {description: 'My second rating'}],
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
          score: 0,
        },
        submitted_or_assessed_at: time1,
      },
      {
        id: 2,
        score: 1,
        percent: 0.1,
        assignment: {
          id: 'live_assessments/assessment_1',
          name: 'My assessment',
          html_url: 'http://bar',
          submission_types: 'magic_marker',
          score: 0,
        },
        submitted_or_assessed_at: time2,
      },
    ],
    title: 'My outcome',
    score: 1,
  },
  expanded: false,
  onExpansionChange: () => {},
  ...props,
})

it('renders correctly expanded', () => {
  const {getByText, getByRole} = render(<Outcome {...defaultProps()} expanded={true} />)
  expect(getByText('My outcome')).not.toBeNull()
  expect(getByRole('list')).not.toBeNull()
})

it('renders correctly expanded with no results', () => {
  const props = defaultProps()
  props.outcome.results = []
  const {getByText} = render(<Outcome {...props} expanded={true} />)
  expect(getByText(/Not yet assessed/)).not.toBeNull()
})

it('renders correctly expanded with no results or assignments', () => {
  const props = defaultProps()
  props.outcome.results = []
  props.outcome.assignments = []
  const {getByText} = render(<Outcome {...props} expanded={true} />)
  expect(getByText(/No alignments are available/)).not.toBeNull()
})

describe('header', () => {
  it('includes the outcome name', () => {
    const {getByText} = render(<Outcome {...defaultProps()} />)
    expect(getByText('My outcome')).not.toBeNull()
  })

  it('includes mastery when mastered', () => {
    const props = defaultProps()
    props.outcome.mastered = true
    const {getByText} = render(<Outcome {...props} />)
    expect(getByText('Mastered')).not.toBeNull()
  })

  it('includes non-mastery when not mastered', () => {
    const {getByText} = render(<Outcome {...defaultProps()} />)
    expect(getByText('Not mastered')).not.toBeNull()
  })

  it('shows correct number of alignments', () => {
    const {getByText} = render(<Outcome {...defaultProps()} />)
    expect(getByText('1 alignment')).not.toBeNull()
  })

  it('shows points if only some results have hide points enabled', () => {
    const props = defaultProps()
    props.outcome.results = [
      result({id: 1, hide_points: false}),
      result({id: 2, hide_points: true}),
    ]
    const {getByText} = render(<Outcome {...props} />)
    expect(getByText('1/5')).not.toBeNull()
  })

  it('does not show points if all results have hide points enabled', () => {
    const props = defaultProps()
    props.outcome.results = [result({id: 1, hide_points: true}), result({id: 2, hide_points: true})]
    const {queryByText} = render(<Outcome {...props} />)
    expect(queryByText('1/5')).toBeNull()
  })
})

it('includes the individual results', () => {
  const {getAllByRole} = render(<Outcome {...defaultProps()} expanded={true} />)
  const results = getAllByRole('listitem')
  expect(results).toHaveLength(2)
})

it('renders the results by most recent', () => {
  const props = defaultProps()
  const now = new Date()
  const minuteAgo = new Date(now - 60000)
  const hourAgo = new Date(now - 3600000)
  const yearishAgo = new Date(now - 3600000 * 24 * 360)
  props.outcome.results = [
    result({id: 1, date: hourAgo}, {name: 'hour ago'}),
    result({id: 2, date: now}, {name: 'now'}),
    result({id: 3, date: minuteAgo}, {name: 'minute ago'}),
    result({id: 4, date: yearishAgo}, {name: 'year ago'}),
  ]

  const {getAllByRole} = render(<Outcome {...props} expanded={true} />)
  const results = getAllByRole('listitem')
  expect(results).toHaveLength(4)
  expect(within(results[0]).getByText('now')).not.toBeNull()
  expect(within(results[1]).getByText('minute ago')).not.toBeNull()
  expect(within(results[2]).getByText('hour ago')).not.toBeNull()
  expect(within(results[3]).getByText('year ago')).not.toBeNull()
})

describe('handleToggle()', () => {
  it('calls onExpansionChange with the correct data', () => {
    const props = defaultProps()
    props.onExpansionChange = jest.fn()

    const {getByText} = render(<Outcome {...props} />)
    fireEvent.click(getByText(/Toggle alignment details/)) // expand
    expect(props.onExpansionChange).toHaveBeenCalledWith('outcome', 100, true)
  })
})

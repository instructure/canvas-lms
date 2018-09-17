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
import { Set } from 'immutable'
import OutcomeGroup from '../OutcomeGroup'

const outcome = (id, title) => ({
  id,
  title,
  assignments: [],
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
      percent: 0.1,
      assignment: {
        id: 2,
        name: 'My alignment',
        html_url: 'http://foo',
        submission_types: ''
      }
    }
  ]
})

const defaultProps = (props = {}) => (
  Object.assign({
    outcomeGroup: {
      id: 10,
      title: 'My group'
    },
    outcomes: [
      {
        id: 1,
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
              id: 1,
              html_url: 'http://foo',
              name: 'My assignment',
              submission_types: 'online_quiz'
            }
          }
        ],
        title: 'My outcome'
      }
    ],
    expanded: false,
    expandedOutcomes: Set(),
    onExpansionChange: () => {}
  }, props)
)

it('renders the OutcomeGroup component', () => {
  const wrapper = shallow(<OutcomeGroup {...defaultProps()}/>)
  expect(wrapper.debug()).toMatchSnapshot()
})

describe('header', () => {
  it('includes the outcome group name', () => {
    const wrapper = shallow(<OutcomeGroup {...defaultProps()}/>)
    const header = wrapper.find('ToggleGroup')
    const summary = render(header.prop('summary'))
    expect(summary.text()).toMatch('My group')
  })
})

it('includes the individual outcomes', () => {
  const wrapper = shallow(<OutcomeGroup {...defaultProps()} />)
  expect(wrapper.find('Outcome')).toHaveLength(1)
})

it('renders correctly expanded', () => {
  const wrapper = shallow(<OutcomeGroup {...defaultProps()} expanded />)
  expect(wrapper.debug()).toMatchSnapshot()
})

it('renders outcomes in alphabetical order by title', () => {
  const props = defaultProps({
    outcomes: [
      outcome(1, 'ZZ Top'),
      outcome(2, 'Aardvark'),
      outcome(3, 'abba'),
      outcome(4, 'Aerosmith')
    ]
  })
  const wrapper = shallow(<OutcomeGroup {...props} />)
  const outcomes = wrapper.find('Outcome')
  expect(outcomes).toHaveLength(4)
  expect(outcomes.get(0).props.outcome.title).toEqual('Aardvark')
  expect(outcomes.get(1).props.outcome.title).toEqual('abba')
  expect(outcomes.get(2).props.outcome.title).toEqual('Aerosmith')
  expect(outcomes.get(3).props.outcome.title).toEqual('ZZ Top')
})

describe('handleToggle()', () => {
  it('calls the correct onExpansionChange callback', () => {
    const props = defaultProps()
    props.onExpansionChange = jest.fn()
    const wrapper = shallow(<OutcomeGroup {...props} />)
    wrapper.instance().handleToggle(null, true)
    expect(props.onExpansionChange).toBeCalledWith('group', 10, true)
  })
})

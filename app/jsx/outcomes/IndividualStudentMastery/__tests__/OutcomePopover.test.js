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
import { shallow } from 'enzyme'
import OutcomePopover from '../OutcomePopover'

const time1 = new Date(Date.UTC(2018, 1, 1, 7, 1, 0))
const time2 = new Date(Date.UTC(2018, 1, 1, 8, 1, 0))

const defaultProps = (props = {}) => (
  Object.assign({
    outcome: {
      id: 1,
      assignments: [],
      expansionId: 100,
      mastered: false,
      mastery_points: 3,
      points_possible: 5,
      calculation_method: 'highest',
      score: 3,
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
            submission_types: 'online_quiz',
            score: 0
          },
          submitted_or_assessed_at: time1
        },
        {
          id: 1,
          score: 7,
          percent: 0.7,
          assignment: {
            id: 2,
            html_url: 'http://bar',
            name: 'Assignment 2',
            submission_types: 'online_quiz',
            score: 3
          },
          submitted_or_assessed_at: time2
        }
      ],
      title: 'My outcome'
    },
    outcomeProficiency: {
      ratings: [
        { color: 'blue', description: "I am blue", points: 10},
        { color: 'green', description: "I am Groot", points: 5},
        { color: 'red', description: "I am red", points: 0}
      ]
    }
  }, props)
)

it('renders the OutcomePopover component', () => {
  const wrapper = shallow(<OutcomePopover {...defaultProps()}/>)
  expect(wrapper.debug()).toMatchSnapshot()
})

it('renders correctly with no results', () => {
  const props = defaultProps()
  props.outcome.results = []
  const wrapper = shallow(<OutcomePopover {...props}/>)
  expect(wrapper.debug()).toMatchSnapshot()
})

it('renders correctly with no custom outcomeProficiency', () => {
  const props = defaultProps()
  props.outcomeProficiency = null
  const wrapper = shallow(<OutcomePopover {...props}/>)
  expect(wrapper.debug()).toMatchSnapshot()
})

it('properly expands details for screenreader users', () => {
  const props = defaultProps()
  const wrapper = shallow(<OutcomePopover {...props}/>)
  expect(wrapper.state('moreInformation')).toEqual(false)
  wrapper.find('Link').simulate('click')
  expect(wrapper.state('moreInformation')).toEqual(true)
})

describe('latestTime', () => {
  it('properly returns the most recent submission time', () => {
    const props = defaultProps()
    const wrapper = shallow(<OutcomePopover {...props}/>)
    expect(wrapper.instance().latestTime()).toEqual(time1)
  })

  it('properly returns nothing when there are no results', () => {
    const props = defaultProps()
    props.outcome.results = []
    const wrapper = shallow(<OutcomePopover {...props}/>)
    expect(wrapper.instance().latestTime()).toBeNull()
  })
})

describe('getSelectedRating', () => {
  it('properly returns the custom proficiency level', () => {
    const props = defaultProps()
    const wrapper = shallow(<OutcomePopover {...props}/>)
    const rating = wrapper.instance().getSelectedRating()
    expect(rating.description).toEqual('I am Groot')
  })

it('properly returns the default proficiency level', () => {
  const props = defaultProps()
    props.outcomeProficiency = null
    const wrapper = shallow(<OutcomePopover {...props}/>)
    const rating = wrapper.instance().getSelectedRating()
    expect(rating.description).toEqual('Meets Mastery')
  })
})

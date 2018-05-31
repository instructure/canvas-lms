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
    const header = wrapper.find('ToggleDetails')
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

it('passes expanded=true to the child outcome when expanded', () => {
  const props = defaultProps()
  props.expandedOutcomes = Set([100])
  const wrapper = shallow(<OutcomeGroup {...props} />)
  expect(wrapper.find('Outcome').prop('expanded')).toBe(true)
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

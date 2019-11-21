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
import {mount, shallow} from 'enzyme'
import {Set} from 'immutable'
import IndividualStudentMastery from '../index'
import fetchOutcomes from '../fetchOutcomes'

jest.mock('../fetchOutcomes')

beforeEach(() => {
  fetchOutcomes.mockImplementation(() => Promise.resolve(null))
})

const props = {
  studentId: 12,
  courseId: 110,
  onExpansionChange: jest.fn()
}

it('renders the component', () => {
  const wrapper = shallow(<IndividualStudentMastery {...props} />)
  expect(wrapper).toMatchSnapshot()
})

it('attempts to load when mounted', () => {
  mount(<IndividualStudentMastery {...props} />)
  expect(fetchOutcomes).toHaveBeenCalled()
})

it('renders loading before promise resolves', () => {
  fetchOutcomes.mockImplementation(() => new Promise(() => {})) // unresolved promise
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  expect(wrapper.find('Spinner')).toHaveLength(1)
})

it('renders error when error occurs during fetch', async () => {
  fetchOutcomes.mockImplementation(() => Promise.reject(new Error('foo')))
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  await wrapper.instance().componentDidMount()
  expect(wrapper.text()).toMatch('An error occurred')
})

it('renders empty if no groups are returned', async () => {
  fetchOutcomes.mockImplementation(() => Promise.resolve({outcomeGroups: [], outcomes: []}))
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  await wrapper.instance().componentDidMount()
  expect(wrapper.text()).toMatch('There are no outcomes in the course')
})

it('renders outcome groups if they are returned', async () => {
  fetchOutcomes.mockImplementation(() =>
    Promise.resolve({
      outcomeGroups: [{id: 1, title: 'Group'}],
      outcomes: []
    })
  )
  const wrapper = shallow(<IndividualStudentMastery {...props} />)
  await wrapper.instance().componentDidMount()
  expect(wrapper.update().find('OutcomeGroup')).toHaveLength(1)
})

describe('expand and contract', () => {
  beforeEach(() => {
    fetchOutcomes.mockImplementation(() =>
      Promise.resolve({
        outcomeGroups: [{id: 1, title: 'Group'}],
        outcomes: [
          {
            id: 2,
            expansionId: 100,
            groupId: 1,
            title: 'Outcome',
            mastered: false,
            mastery_points: 0,
            points_possible: 0,
            calculation_method: 'highest',
            assignments: [],
            results: [],
            ratings: []
          }
        ]
      })
    )
  })

  it('toggles elements to expanded when event fired', async () => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    await wrapper.instance().componentDidMount()
    wrapper.instance().onElementExpansionChange('outcome', 100, true)
    expect(wrapper.state('expandedOutcomes').equals(Set.of(100))).toBe(true)
    wrapper.instance().onElementExpansionChange('outcome', 100, false)
    expect(wrapper.state('expandedOutcomes').equals(Set())).toBe(true)
  })

  it('contracts child outcomes when a group is contracted', async () => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    await wrapper.instance().componentDidMount()
    wrapper.setState({expandedGroups: Set.of(1), expandedOutcomes: Set.of(100)}, () => {
      wrapper.instance().onElementExpansionChange('group', 1, false)
    })
    expect(wrapper.state('expandedOutcomes').equals(Set())).toBe(true)
  })

  it('expands all when expand() is called', async () => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    await wrapper.instance().componentDidMount()
    wrapper.instance().expand()
    expect(wrapper.state('expandedGroups').equals(Set.of(1))).toBe(true)
    expect(wrapper.state('expandedOutcomes').equals(Set.of(100))).toBe(true)
  })

  it('contracts all when contract() is called', async () => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    await wrapper.instance().componentDidMount()
    wrapper.setState({expandedOutcomes: Set.of(100), expandedGroups: Set.of(1)}, () => {
      wrapper.instance().contract()
    })
    expect(wrapper.state('expandedGroups').equals(Set())).toBe(true)
    expect(wrapper.state('expandedOutcomes').equals(Set())).toBe(true)
  })

  it('notifies when expansion is changed', async () => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    await wrapper.instance().componentDidMount()
    wrapper.instance().onElementExpansionChange('outcome', 100, true)
    expect(props.onExpansionChange).toHaveBeenLastCalledWith(true, true)
    wrapper.instance().onElementExpansionChange('group', 1, true)
    expect(props.onExpansionChange).toHaveBeenLastCalledWith(true, false)
    wrapper.instance().contract()
    expect(props.onExpansionChange).toHaveBeenLastCalledWith(false, true)
  })
})

it('renders outcome groups in alphabetical order by title', async () => {
  fetchOutcomes.mockImplementation(() =>
    Promise.resolve({
      outcomeGroups: [
        {id: 1, title: 'ZZ Top Albums'},
        {id: 2, title: 'Aerosmith Albums'},
        {id: 3, title: 'Aardvark Albums'},
        {id: 4, title: 'abba Albums'}
      ],
      outcomes: []
    })
  )
  const wrapper = shallow(<IndividualStudentMastery {...props} />)
  await wrapper.instance().componentDidMount()
  const groups = wrapper.find('OutcomeGroup')
  expect(groups).toHaveLength(4)
  expect(groups.get(0).props.outcomeGroup.title).toEqual('Aardvark Albums')
  expect(groups.get(1).props.outcomeGroup.title).toEqual('abba Albums')
  expect(groups.get(2).props.outcomeGroup.title).toEqual('Aerosmith Albums')
  expect(groups.get(3).props.outcomeGroup.title).toEqual('ZZ Top Albums')
})

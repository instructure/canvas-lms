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
import {mount} from 'enzyme'
import {render, within} from '@testing-library/react'
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
  onExpansionChange: jest.fn(),
}

it('renders the component', () => {
  const {getByText} = render(<IndividualStudentMastery {...props} />)
  expect(getByText('Loading outcome results')).not.toBeNull()
})

it('attempts to load when mounted', () => {
  render(<IndividualStudentMastery {...props} />)
  expect(fetchOutcomes).toHaveBeenCalled()
})

it('renders error when error occurs during fetch', async () => {
  fetchOutcomes.mockImplementation(() => Promise.reject(new Error('foo')))
  const {findByText} = render(<IndividualStudentMastery {...props} />)
  expect(await findByText(/An error occurred/)).not.toBeNull()
})

it('renders empty if no groups are returned', async () => {
  fetchOutcomes.mockImplementation(() => Promise.resolve({outcomeGroups: [], outcomes: []}))
  const {findByText} = render(<IndividualStudentMastery {...props} />)
  expect(await findByText(/There are no outcomes in the course/)).not.toBeNull()
})

it('renders outcome groups if they are returned', async () => {
  fetchOutcomes.mockImplementation(() =>
    Promise.resolve({
      outcomeGroups: [{id: 1, title: 'Group'}],
      outcomes: [],
    })
  )
  const {findByText} = render(<IndividualStudentMastery {...props} />)
  expect(await findByText('Group')).not.toBeNull()
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
            ratings: [],
          },
        ],
      })
    )
  })

  it('renders outcome groups in alphabetical order by title', async () => {
    fetchOutcomes.mockImplementation(() =>
      Promise.resolve({
        outcomeGroups: [
          {id: 1, title: 'ZZ Top Albums'},
          {id: 2, title: 'Aerosmith Albums'},
          {id: 3, title: 'Aardvark Albums'},
          {id: 4, title: 'abba Albums'},
        ],
        outcomes: [],
      })
    )
    const {findAllByRole} = render(<IndividualStudentMastery {...props} />)
    const groups = await findAllByRole('listitem')
    expect(groups).toHaveLength(4)
    expect(within(groups[0]).getByText('Aardvark Albums')).not.toBeNull()
    expect(within(groups[1]).getByText('abba Albums')).not.toBeNull()
    expect(within(groups[2]).getByText('Aerosmith Albums')).not.toBeNull()
    expect(within(groups[3]).getByText('ZZ Top Albums')).not.toBeNull()
  })

  // legacy enzyme tests
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

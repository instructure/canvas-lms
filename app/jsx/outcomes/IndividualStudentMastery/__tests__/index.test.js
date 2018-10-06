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
import { mount, shallow } from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'
import { Set } from 'immutable'
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
  const wrapper = shallow(<IndividualStudentMastery {...props}/>)
  expect(wrapper.debug()).toMatchSnapshot()
})

it('attempts to load when mounted', () => {
  mount(<IndividualStudentMastery {...props} />)
  expect(fetchOutcomes).toBeCalled()
})

it('renders loading before promise resolves', () => {
  fetchOutcomes.mockImplementation(() => new Promise((() => {}))) // unresolved promise
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  expect(wrapper.find('Spinner')).toHaveLength(1)
})

it('renders error when error occurs during fetch', (done) => {
  fetchOutcomes.mockImplementation(() => Promise.reject(new Error('foo')))
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  setTimeout(() => {
    expect(wrapper.text()).toMatch('An error occurred')
    done()
  }, 1)
})

it('renders empty if no groups are returned', (done) => {
  fetchOutcomes.mockImplementation(() => Promise.resolve({ outcomeGroups: [], outcomes: [] }))
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  setTimeout(() => {
    expect(wrapper.text()).toMatch('There are no outcomes')
    done()
  }, 1)
})

it('renders outcome groups if they are returned', (done) => {
  fetchOutcomes.mockImplementation(() => Promise.resolve({
    outcomeGroups: [{ id: 1, title: 'Group' }],
    outcomes: []
  }))
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  setTimeout(() => {
    expect(wrapper.update().find('OutcomeGroup')).toHaveLength(1)
    done()
  }, 1)
})

describe('expand and contract', () => {
  beforeEach(() => {
    fetchOutcomes.mockImplementation(() => Promise.resolve({
      outcomeGroups: [{ id: 1, title: 'Group' }],
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
    }))
  })

  it('toggles elements to expanded when event fired', (done) => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    setTimeout(() => {
      wrapper.instance().onElementExpansionChange('outcome', 100, true)
      expect(wrapper.state('expandedOutcomes').equals(Set.of(100))).toBe(true)
      wrapper.instance().onElementExpansionChange('outcome', 100, false)
      expect(wrapper.state('expandedOutcomes').equals(Set())).toBe(true)
      done()
    })
  })

  it('contracts child outcomes when a group is contracted', (done) => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    setTimeout(() => {
      wrapper.setState({ expandedGroups: Set.of(1), expandedOutcomes: Set.of(100) }, () => {
        wrapper.instance().onElementExpansionChange('group', 1, false)
        setTimeout(() => {
          expect(wrapper.state('expandedOutcomes').equals(Set())).toBe(true)
          done()
        })
      })
    })
  })

  it('expands all when expand() is called', (done) => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    setTimeout(() => {
      wrapper.instance().expand()
      setTimeout(() => {
        expect(wrapper.state('expandedGroups').equals(Set.of(1))).toBe(true)
        expect(wrapper.state('expandedOutcomes').equals(Set.of(100))).toBe(true)
        done()
      })
    })
  })

  it('contracts all when contract() is called', (done) => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    setTimeout(() => {
      wrapper.setState({ expandedOutcomes: Set.of(100), expandedGroups: Set.of(1) }, () => {
        wrapper.instance().contract()
        setTimeout(() => {
          expect(wrapper.state('expandedGroups').equals(Set())).toBe(true)
          expect(wrapper.state('expandedOutcomes').equals(Set())).toBe(true)
          done()
        })
      })
    })
  })

  it('notifies when expansion is changed', (done) => {
    const wrapper = mount(<IndividualStudentMastery {...props} />)
    setTimeout(() => {
      wrapper.instance().onElementExpansionChange('outcome', 100, true)
      expect(props.onExpansionChange).lastCalledWith(true, true)
      wrapper.instance().onElementExpansionChange('group', 1, true)
      expect(props.onExpansionChange).lastCalledWith(true, false)
      wrapper.instance().contract()
      expect(props.onExpansionChange).lastCalledWith(false, true)
      done()
    })
  })
})

it('renders outcome groups in alphabetical order by title', (done) => {
  fetchOutcomes.mockImplementation(() => Promise.resolve({
    outcomeGroups: [
      { id: 1, title: 'ZZ Top Albums' },
      { id: 2, title: 'Aerosmith Albums' },
      { id: 3, title: 'Aardvark Albums' },
      { id: 4, title: 'abba Albums' }
    ],
    outcomes: []
  }))
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  setTimeout(() => {
    const groups = wrapper.find('OutcomeGroup')
    expect(groups).toHaveLength(4)
    expect(groups.get(0).props.outcomeGroup.title).toEqual('Aardvark Albums')
    expect(groups.get(1).props.outcomeGroup.title).toEqual('abba Albums')
    expect(groups.get(2).props.outcomeGroup.title).toEqual('Aerosmith Albums')
    expect(groups.get(3).props.outcomeGroup.title).toEqual('ZZ Top Albums')
    done()
  })
})

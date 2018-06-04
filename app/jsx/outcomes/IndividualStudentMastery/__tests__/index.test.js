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
import { mount, shallow } from 'enzyme'
import IndividualStudentMastery from '../index'
import fetchOutcomes from '../fetchOutcomes'

jest.mock('../fetchOutcomes')

beforeEach(() => {
  fetchOutcomes.mockImplementation(() => Promise.resolve(null))
})

const props = {
  studentId: 12,
  courseId: 110
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
  fetchOutcomes.mockImplementation(() => Promise.resolve({ outcomeGroups: [{ id: 1, title: 'Group' }], outcomes: [] }))
  const wrapper = mount(<IndividualStudentMastery {...props} />)
  setTimeout(() => {
    expect(wrapper.update().find('OutcomeGroup')).toHaveLength(1)
    done()
  }, 1)
})

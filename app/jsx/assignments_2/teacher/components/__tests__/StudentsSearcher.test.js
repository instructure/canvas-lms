/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent} from 'react-testing-library'
import MockDate from 'mockdate'
import CanvasValidatedMockedProvider from 'jsx/__tests__/CanvasValidatedMockedProvider'
import {STUDENT_SEARCH_QUERY} from '../../assignmentData'
import {mockAssignment, mockSubmission, mockUser, closest} from '../../test-utils'
import StudentsSearcher from '../StudentsSearcher'

function mockRequest({users = [mockUser()], variables = {}}) {
  const submissions = users.map(user => mockSubmission({user}))
  const assignment = mockAssignment({
    submissions: {nodes: submissions}
  })
  return {
    request: {
      query: STUDENT_SEARCH_QUERY,
      variables: {
        assignmentId: assignment.lid,
        ...variables
      }
    },
    result: {
      data: {assignment}
    }
  }
}

// each element of users and variables defines a request, its variables, and the
// users that should be returned.
function renderStudentsSearcher(usersAndVariables) {
  if (usersAndVariables === undefined) {
    usersAndVariables = [{users: [mockUser()], variables: {}}]
  }
  const requests = usersAndVariables.map(uav => mockRequest(uav))
  const fns = render(
    <CanvasValidatedMockedProvider mocks={requests} addTypename={false}>
      <StudentsSearcher assignment={mockAssignment()} />
    </CanvasValidatedMockedProvider>
  )
  return fns
}

beforeEach(() => jest.useFakeTimers())

describe('StudentsSearcher', () => {
  it('renders a spinner while loading', () => {
    const {getByText} = renderStudentsSearcher()
    expect(getByText('Loading...')).toBeInTheDocument()
  })

  it('initially loads all students and renders results', () => {
    const foo = mockUser({lid: 'foo', shortName: 'foo'})
    const bar = mockUser({lid: 'bar', shortName: 'bar'})
    // const submissions = [mockSubmission({user: foo}), mockSubmission({user: bar})]
    const {getByText} = renderStudentsSearcher([{users: [foo, bar]}])
    jest.runAllTimers()
    expect(getByText(foo.shortName)).toBeInTheDocument()
    expect(getByText(bar.shortName)).toBeInTheDocument()
  })

  it('sorts by username', () => {
    const {getByText} = renderStudentsSearcher([
      {},
      {
        users: [mockUser({shortName: 'searched user'})],
        variables: {orderBy: [{field: 'username', direction: 'ascending'}]}
      },
      {
        users: [mockUser({shortName: 'reverse searched user'})],
        variables: {orderBy: [{field: 'username', direction: 'descending'}]}
      }
    ])
    jest.runAllTimers()
    fireEvent.click(closest(getByText('Name'), 'button'))
    jest.runAllTimers()
    expect(getByText('searched user')).toBeInTheDocument()

    fireEvent.click(closest(getByText('Name'), 'button'))
    jest.runAllTimers()
    expect(getByText('reverse searched user')).toBeInTheDocument()
  })

  it('sorts by score', () => {
    const {getByText} = renderStudentsSearcher([
      {},
      {
        users: [mockUser({shortName: 'searched user'})],
        variables: {orderBy: [{field: 'score', direction: 'ascending'}]}
      }
    ])
    jest.runAllTimers()
    fireEvent.click(closest(getByText('Score'), 'button'))
    jest.runAllTimers()
    expect(getByText('searched user')).toBeInTheDocument()
  })

  it('sorts by submission date', () => {
    const {getByText} = renderStudentsSearcher([
      {},
      {
        users: [mockUser({shortName: 'searched user'})],
        variables: {orderBy: [{field: 'submitted_at', direction: 'ascending'}]}
      }
    ])
    jest.runAllTimers()
    fireEvent.click(closest(getByText('Submission Date'), 'button'))
    jest.runAllTimers()
    expect(getByText('searched user')).toBeInTheDocument()
  })

  // _.debounce requires time to actually advance
  describe('with MockDate', () => {
    afterEach(() => {
      MockDate.reset()
    })

    it('runs the userSearch query with a delay', () => {
      const {getByText, queryByText, getByLabelText} = renderStudentsSearcher([
        {},
        {users: [mockUser({shortName: 'searched user'})], variables: {userSearch: 'search'}}
      ])
      jest.runAllTimers()
      const searchInput = getByLabelText('Search by student name')
      const startNow = Date.now()
      fireEvent.change(searchInput, {target: {value: 'search'}})

      // initially hasn't searched yet
      MockDate.set(startNow + 500)
      jest.advanceTimersByTime(500)
      expect(getByText(mockUser().shortName)).toBeInTheDocument()
      expect(queryByText('searched user')).toBeNull()

      // then does the search after the delay
      MockDate.set(startNow + 1000)
      jest.advanceTimersByTime(500)
      expect(getByText('searched user')).toBeInTheDocument()
    })

    it('displays a message and does not load when 0 < search characters < 3', () => {
      const {getByText, getByLabelText} = renderStudentsSearcher()
      jest.runAllTimers()
      const searchInput = getByLabelText('Search by student name')
      const startNow = Date.now()
      fireEvent.change(searchInput, {target: {value: '12'}})
      MockDate.set(startNow + 1000)
      jest.runAllTimers()
      expect(getByText(/at least 3 characters/)).toBeInTheDocument()
    })
  })
})

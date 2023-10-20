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
import {render, fireEvent} from '@testing-library/react'
import CanvasValidatedMockedProvider from '@canvas/validated-apollo-mocked-provider'
import {STUDENT_SEARCH_QUERY} from '../../../assignmentData'
import {mockAssignment, mockSubmission, mockUser, closest} from '../../../test-utils'
import StudentsSearcher from '../StudentsSearcher'

function mockRequest({users = [mockUser()], variables = {}}) {
  const submissions = users.map(user => mockSubmission({user}))
  const assignment = mockAssignment({
    submissions: {nodes: submissions},
  })
  return {
    request: {
      query: STUDENT_SEARCH_QUERY,
      variables: {
        assignmentId: assignment.lid,
        ...variables,
      },
    },
    result: {
      data: {assignment},
    },
  }
}

// each element of users and variables defines a request, its variables, and the
// users that should be returned.
function renderStudentsSearcher(usersAndVariables, useAssignment) {
  if (usersAndVariables === undefined) {
    usersAndVariables = [{users: [mockUser()], variables: {}}]
  }
  const requests = usersAndVariables.map(uav => mockRequest(uav))
  const assignment = useAssignment || mockAssignment()
  const fns = render(
    <CanvasValidatedMockedProvider mocks={requests} addTypename={false}>
      <StudentsSearcher assignment={assignment} />
    </CanvasValidatedMockedProvider>
  )
  return fns
}

beforeEach(() => jest.useFakeTimers())

describe('StudentsSearcher', () => {
  it('renders a spinner while loading', () => {
    const {getByText} = renderStudentsSearcher()
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('shows action buttons when assignment is published', () => {
    const {getByText} = renderStudentsSearcher()
    expect(closest(getByText('Speedgrader'), 'a')).toBeTruthy()
    expect(closest(getByText('Message Students'), 'button')).toBeTruthy()
  })

  it('enables "Message Students" when students are not anonymized', () => {
    const assignment = mockAssignment({anonymizeStudents: false})
    const {getByText} = renderStudentsSearcher([], assignment)
    const button = closest(getByText('Message Students'), 'button')
    expect(button.disabled).toBeFalsy()
  })

  it('disables "Message Students" when students are anonymized', () => {
    const assignment = mockAssignment({anonymizeStudents: true})
    const {getByText} = renderStudentsSearcher([], assignment)
    const button = closest(getByText('Message Students'), 'button')
    expect(button.disabled).toBeTruthy()
  })

  it('should open speedgrader link in a new tab', () => {
    const {getByText} = renderStudentsSearcher()
    const sgLink = closest(getByText('Speedgrader'), 'a')
    expect(sgLink.getAttribute('href')).toMatch(
      /\/courses\/course-lid\/gradebook\/speed_grader\?assignment_id=assignment-lid/
    )
    expect(sgLink.getAttribute('target')).toEqual('_blank')
  })

  it('does not render submission and grading links when assignment is not published', () => {
    const assignment = mockAssignment({state: 'unpublished'})
    const {queryByText} = renderStudentsSearcher([], assignment)
    expect(queryByText('Speedgrader', {exact: false})).toBeNull()
    expect(queryByText('Message Students', {exact: false})).toBeNull()
  })

  it('initially loads all students and renders results', () => {
    const foo = mockUser({lid: 'foo', shortName: 'foo'})
    const bar = mockUser({lid: 'bar', shortName: 'bar'})
    const {getByText} = renderStudentsSearcher([{users: [foo, bar]}])
    jest.runOnlyPendingTimers()
    expect(getByText(foo.shortName)).toBeInTheDocument()
    expect(getByText(bar.shortName)).toBeInTheDocument()
  })

  it('sorts by username', () => {
    const {getByText} = renderStudentsSearcher([
      {},
      {
        users: [mockUser({shortName: 'searched user'})],
        variables: {orderBy: [{field: 'username', direction: 'ascending'}]},
      },
      {
        users: [mockUser({shortName: 'reverse searched user'})],
        variables: {orderBy: [{field: 'username', direction: 'descending'}]},
      },
    ])
    jest.runOnlyPendingTimers()
    fireEvent.click(closest(getByText('Name'), 'button'))
    jest.runOnlyPendingTimers()
    expect(getByText('searched user')).toBeInTheDocument()

    fireEvent.click(closest(getByText('Name'), 'button'))
    jest.runOnlyPendingTimers()
    expect(getByText('reverse searched user')).toBeInTheDocument()
  })

  it('sorts by score', () => {
    const {getByText} = renderStudentsSearcher([
      {},
      {
        users: [mockUser({shortName: 'searched user'})],
        variables: {orderBy: [{field: 'score', direction: 'ascending'}]},
      },
    ])
    jest.runOnlyPendingTimers()
    fireEvent.click(closest(getByText('Score'), 'button'))
    jest.runOnlyPendingTimers()
    expect(getByText('searched user')).toBeInTheDocument()
  })

  it('sorts by submission date', () => {
    const {getByText} = renderStudentsSearcher([
      {},
      {
        users: [mockUser({shortName: 'searched user'})],
        variables: {orderBy: [{field: 'submitted_at', direction: 'ascending'}]},
      },
    ])
    jest.runOnlyPendingTimers()
    fireEvent.click(closest(getByText('Submission Date'), 'button'))
    jest.runOnlyPendingTimers()
    expect(getByText('searched user')).toBeInTheDocument()
  })

  it('hides extended filters by default', () => {
    const {queryByTestId} = renderStudentsSearcher()
    jest.runOnlyPendingTimers()
    expect(queryByTestId('assignToFilter')).toBeNull()
    expect(queryByTestId('attemptsFilter')).toBeNull()
    expect(queryByTestId('assignToFilter')).toBeNull()
  })

  it('toggles extended filters when button is clicked', () => {
    const {queryByTestId, getByTestId, getByText} = renderStudentsSearcher()
    fireEvent.click(closest(getByText('Filter'), 'button'))
    jest.runOnlyPendingTimers()
    expect(getByTestId('assignToFilter')).toBeInTheDocument()
    expect(getByTestId('attemptFilter')).toBeInTheDocument()
    expect(getByTestId('statusFilter')).toBeInTheDocument()

    fireEvent.click(closest(getByText('Filter'), 'button'))
    jest.runOnlyPendingTimers()
    expect(queryByTestId('assignToFilter')).toBeNull()
    expect(queryByTestId('attemptFilter')).toBeNull()
    expect(queryByTestId('assignToFilter')).toBeNull()
  })

  it('runs the userSearch query with a delay', () => {
    const {getByText, queryByText, getByLabelText} = renderStudentsSearcher([
      {},
      {users: [mockUser({shortName: 'searched user'})], variables: {userSearch: 'search'}},
    ])
    jest.runOnlyPendingTimers()
    const searchInput = getByLabelText('Search by student name')
    fireEvent.change(searchInput, {target: {value: 'search'}})

    // initially hasn't searched yet
    jest.advanceTimersByTime(500)
    expect(getByText(mockUser().shortName)).toBeInTheDocument()
    expect(queryByText('searched user')).toBeNull()

    // then does the search after the delay
    jest.advanceTimersByTime(500)
    expect(getByText('searched user')).toBeInTheDocument()
  })

  it('displays a message and does not load when 0 < search characters < 3', () => {
    const {getByText, getByLabelText} = renderStudentsSearcher()
    jest.runOnlyPendingTimers()
    const searchInput = getByLabelText('Search by student name')
    fireEvent.change(searchInput, {target: {value: '12'}})
    jest.advanceTimersByTime(1000)
    expect(getByText(/at least 3 characters/)).toBeInTheDocument()
  })
})

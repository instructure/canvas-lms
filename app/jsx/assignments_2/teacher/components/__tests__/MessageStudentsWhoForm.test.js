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
import {closest, mockAssignment, mockSubmission, mockUser} from '../../test-utils'

import MessageStudentsWhoForm from '../MessageStudentsWhoForm'

function mockAssignmentWithStudents(students) {
  const submissions = students.map(student => mockSubmission({user: mockUser(student)}))
  return mockAssignment({submissions: {nodes: submissions}})
}

describe('MessageStudentsWhoForm', () => {
  it('shows a list of students to message', () => {
    const assignment = mockAssignmentWithStudents([
      {lid: '1', gid: 'g1', name: 'first'},
      {lid: '2', gid: 'g2', name: 'second'},
      {lid: '3', gid: 'g3', name: 'third'}
    ])
    const {getByText} = render(<MessageStudentsWhoForm assignment={assignment} />)
    expect(getByText('first')).toBeInTheDocument()
    expect(getByText('second')).toBeInTheDocument()
    expect(getByText('third')).toBeInTheDocument()
  })

  it('removes students from the list', () => {
    const assignment = mockAssignmentWithStudents([
      {lid: '1', gid: 'g1', name: 'first'},
      {lid: '2', gid: 'g2', name: 'second'}
    ])

    const {getByText, queryByText} = render(<MessageStudentsWhoForm assignment={assignment} />)
    const deleteFirstButton = closest(getByText('first'), 'button')
    fireEvent.click(deleteFirstButton)
    expect(queryByText('first')).toBeNull()
    expect(getByText('second')).toBeInTheDocument()
  })

  // TODO: future tests to implement
  /* eslint-disable jest/no-disabled-tests */
  it.skip('populates selected students when message students who dropdown is changed', () => {
    // need multiple submission statuses to check this
  })
  /* eslint-enable jest/no-disabled-tests */
})

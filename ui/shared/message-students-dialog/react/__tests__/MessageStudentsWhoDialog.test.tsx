/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {fireEvent, render, waitFor} from '@testing-library/react'
import MessageStudentsWhoDialog, {
  Assignment,
  Props as ComponentProps,
  Student
} from '../MessageStudentsWhoDialog'
import {MockedProvider} from '@apollo/react-testing'
import mockGraphqlQuery from '@canvas/graphql-query-mock'
import {createCache} from '@canvas/apollo'
import {OBSERVER_ENROLLMENTS_QUERY} from '../../graphql/Queries'

const students: Student[] = [
  {
    id: '100',
    name: 'Betty Ford',
    sortableName: 'Ford, Betty'
  },
  {
    id: '101',
    name: 'Adam Jones',
    sortableName: 'Jones, Adam'
  },
  {
    id: '102',
    name: 'Charlie Xi',
    sortableName: 'Xi, Charlie'
  },
  {
    id: '103',
    name: 'Dana Smith',
    sortableName: 'Smith, Dana'
  }
]

const scoredAssignment: Assignment = {
  courseId: '1',
  gradingType: 'points',
  id: '100',
  name: 'A pointed assignment',
  nonDigitalSubmission: false
}

const ungradedAssignment: Assignment = {
  courseId: '1',
  gradingType: 'not_graded',
  id: '200',
  name: 'A pointless assignment',
  nonDigitalSubmission: false
}

const passFailAssignment: Assignment = {
  courseId: '1',
  gradingType: 'pass_fail',
  id: '300',
  name: 'A pass-fail assignment',
  nonDigitalSubmission: false
}

const unsubmittableAssignment: Assignment = {
  courseId: '1',
  gradingType: 'no_submission',
  id: '400',
  name: 'An unsubmittable assignment',
  nonDigitalSubmission: true
}

function makeProps(overrides: object = {}): ComponentProps {
  return {
    assignment: scoredAssignment,
    students,
    onClose: () => {},
    onSend: () => {},
    messageAttachmentUploadFolderId: '1',
    ...overrides
  }
}

async function makeMocks(overrides = [], sameStudent = false) {
  const variables = {courseId: '1', studentIds: ['100', '101', '102', '103']}
  const allOverrides = [...overrides, {EnrollmentType: 'ObserverEnrollment'}]

  const resultQuery = await mockGraphqlQuery(OBSERVER_ENROLLMENTS_QUERY, allOverrides, variables)

  const nodes = resultQuery.data?.course.enrollmentsConnection.nodes

  nodes.forEach(function (node, index) {
    node.user.name = 'Observer' + index
    if (sameStudent) {
      node.associatedUser._id = students[0].id
    } else {
      node.associatedUser._id = students[index].id
    }
  })

  return [
    {
      request: {
        query: OBSERVER_ENROLLMENTS_QUERY,
        variables: {
          courseId: '1',
          studentIds: ['100', '101', '102', '103']
        }
      },
      result: resultQuery
    }
  ]
}

describe('MessageStudentsWhoDialog', () => {
  it('hides the list of students and observers initially', async () => {
    const mocks = await makeMocks()

    const {queryByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )
    await waitFor(() => {
      expect(queryByRole('table')).not.toBeInTheDocument()
    })
  })

  it('shows students sorted by sortable name when the table is shown', async () => {
    const mocks = await makeMocks()

    const {getByRole, getAllByRole, findByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )

    const button = await findByRole('button', {name: 'Show all recipients'})
    fireEvent.click(button)
    expect(getByRole('table')).toBeInTheDocument()

    const tableRows = getAllByRole('row') as HTMLTableRowElement[]
    const studentCells = tableRows.map(row => row.cells[0])
    // first cell will be the header
    expect(studentCells).toHaveLength(5)
    expect(studentCells[0]).toHaveTextContent('Students')
    expect(studentCells[1]).toHaveTextContent('Betty Ford')
    expect(studentCells[2]).toHaveTextContent('Adam Jones')
    expect(studentCells[3]).toHaveTextContent('Dana Smith')
    expect(studentCells[4]).toHaveTextContent('Charlie Xi')
  })

  it('shows observers sorted by the sortable name of the associated user when the table is shown', async () => {
    const mocks = await makeMocks()

    const {findByRole, getByRole, getAllByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )

    const button = await findByRole('button', {name: 'Show all recipients'})
    fireEvent.click(button)
    expect(getByRole('table')).toBeInTheDocument()

    const tableRows = getAllByRole('row') as HTMLTableRowElement[]
    const observerCells = tableRows.map(row => row.cells[1])
    // first cell will be the header
    expect(observerCells).toHaveLength(5)
    expect(observerCells[0]).toHaveTextContent('Observers')
    expect(observerCells[1]).toHaveTextContent('Observer0')
    expect(observerCells[2]).toHaveTextContent('Observer1')
    expect(observerCells[3]).toBeNull
    expect(observerCells[4]).toBeNull
  })

  it('shows observers in the same cell sorted by the sortable name when observing the same student', async () => {
    const mocks = await makeMocks([], true)

    const {findByRole, getByRole, getAllByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )
    const button = await findByRole('button', {name: 'Show all recipients'})
    fireEvent.click(button)
    expect(getByRole('table')).toBeInTheDocument()

    const tableRows = getAllByRole('row') as HTMLTableRowElement[]
    const observerCells = tableRows.map(row => row.cells[1])
    // first cell will be the header
    expect(observerCells).toHaveLength(5)
    expect(observerCells[0]).toHaveTextContent('Observers')
    expect(observerCells[1]).toHaveTextContent('Observer0Observer1')
    expect(observerCells[2]).toBeNull
    expect(observerCells[3]).toBeNull
    expect(observerCells[4]).toBeNull
  })

  it('includes the total number of students in the checkbox label', async () => {
    const mocks = await makeMocks()

    const {findByRole} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )
    expect(await findByRole('checkbox', {name: /Students/})).toHaveAccessibleName('4 Students')
  })

  it('includes the total number of observers in the checkbox label', async () => {
    const mocks = await makeMocks()

    const {findByRole} = render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedProvider>
    )
    expect(await findByRole('checkbox', {name: /Observers/})).toHaveAccessibleName('2 Observers')
  })

  describe('available criteria', () => {
    it('includes score-related options but no "Marked incomplete" option for point-based assignments', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Scored more than')
      expect(criteriaLabels).toContain('Scored less than')
      expect(criteriaLabels).not.toContain('Marked incomplete')
    })

    it('includes "Marked incomplete" but no score-related options for pass-fail assignments', async () => {
      const mocks = await makeMocks()

      const {findByLabelText, getAllByRole} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: passFailAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Marked incomplete')
      expect(criteriaLabels).not.toContain('Scored more than')
      expect(criteriaLabels).not.toContain('Scored less than')
    })

    it('does not include "Marked incomplete" or score-related options for ungraded assignments', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: ungradedAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Marked incomplete')
      expect(criteriaLabels).not.toContain('Scored more than')
      expect(criteriaLabels).not.toContain('Scored less than')
    })

    it('includes "Have not yet submitted" if the assignment accepts digital submissions', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Have not yet submitted')
    })

    it('does not include "Have not yet submitted" if the assignment does not accept digital submissions', async () => {
      const mocks = await makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps({assignment: unsubmittableAssignment})} />
        </MockedProvider>
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Have not yet submitted')
    })
  })

  describe('cutoff input', () => {
    it('is shown only when "Scored more than" or "Scored less than" is selected', async () => {
      const mocks = await makeMocks()

      const {getByLabelText, getByRole, queryByLabelText} = render(
        <MockedProvider mocks={mocks} cache={createCache()}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedProvider>
      )
      await waitFor(() => {
        expect(queryByLabelText('Enter score cutoff')).not.toBeInTheDocument()
      })

      const selector = getByLabelText(/For students who/)

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Scored more than'}))
      expect(getByLabelText('Enter score cutoff')).toBeInTheDocument()

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Scored less than'}))
      expect(getByLabelText('Enter score cutoff')).toBeInTheDocument()

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Reassigned'}))
      expect(queryByLabelText('Enter score cutoff')).not.toBeInTheDocument()
    })
  })
})

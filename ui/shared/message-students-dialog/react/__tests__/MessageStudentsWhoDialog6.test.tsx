/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
  type Student,
  type Props as ComponentProps,
  MSWLaunchContext,
} from '../MessageStudentsWhoDialog'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import type {CamelizedAssignment} from '@canvas/grading/grading'
import fakeENV from '@canvas/test-utils/fakeENV'
const students: Student[] = [
  {
    id: '100',
    name: 'Betty Ford',
    grade: undefined,
    redoRequest: false,
    sortableName: 'Ford, Betty',
    score: undefined,
    submittedAt: new Date(Date.now()),
    excused: false,
    workflowState: 'submitted',
  },
  {
    id: '101',
    name: 'Adam Jones',
    grade: undefined,
    redoRequest: false,
    sortableName: 'Jones, Adam',
    score: undefined,
    submittedAt: new Date(Date.now()),
    excused: false,
    workflowState: 'submitted',
  },
  {
    id: '102',
    name: 'Charlie Xi',
    grade: undefined,
    redoRequest: false,
    sortableName: 'Xi, Charlie',
    score: undefined,
    submittedAt: new Date(Date.now()),
    excused: false,
    workflowState: 'submitted',
  },
  {
    id: '103',
    name: 'Dana Smith',
    grade: undefined,
    redoRequest: false,
    sortableName: 'Smith, Dana',
    score: undefined,
    submittedAt: new Date(Date.now()),
    excused: false,
    workflowState: 'submitted',
  },
]

const scoredAssignment: CamelizedAssignment = {
  allowedAttempts: 3,
  courseId: '1',
  dueAt: new Date().toISOString(),
  gradingType: 'points',
  id: '100',
  name: 'A pointed assignment',
  submissionTypes: ['online_text_entry'],
  anonymizeStudents: false,
  anonymousGrading: false,
  gradesPublished: true,
  htmlUrl: 'http://example.com',
  hasRubric: false,
  moderatedGrading: false,
  muted: false,
  pointsPossible: 10,
  postManually: false,
  published: true,
}

const passFailAssignment: CamelizedAssignment = {
  allowedAttempts: -1,
  courseId: '1',
  dueAt: null,
  gradingType: 'pass_fail',
  id: '300',
  name: 'A pass-fail assignment',
  submissionTypes: ['online_text_entry'],
  anonymizeStudents: false,
  anonymousGrading: false,
  gradesPublished: true,
  htmlUrl: 'http://example.com',
  hasRubric: false,
  moderatedGrading: false,
  muted: false,
  pointsPossible: 10,
  postManually: false,
  published: true,
}

function makeProps(overrides: object = {}): ComponentProps {
  return {
    assignment: scoredAssignment,
    students,
    onClose: () => {},
    onSend: () => {},
    messageAttachmentUploadFolderId: '1',
    courseId: '1',
    userId: '345',
    launchContext: MSWLaunchContext.ASSIGNMENT_CONTEXT,
    ...overrides,
  }
}

function makeMocks() {
  queryClient.setQueryData(['ObserversForStudents', '1', '100,101,102,103'], {
    pages: [
      {
        course: {
          enrollmentsConnection: {
            nodes: [
              {
                _id: '123',
                type: 'ObserverEnrollment',
                user: {_id: '456', name: 'Observer0', sortableName: 'Observer0'},
                associatedUser: {_id: '100'},
              },
              {
                _id: '234',
                type: 'ObserverEnrollment',
                user: {_id: '567', name: 'Observer1', sortableName: 'Observer1'},
                associatedUser: {_id: '101'},
              },
            ],
            pageInfo: {hasNextPage: false, endCursor: '123'},
          },
        },
      },
    ],
    pageParams: [null],
  })
}

describe('MessageStudentsWhoDialog', () => {
  beforeEach(() => {
    fakeENV.setup()
    queryClient.clear()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('selected criteria', () => {
    beforeEach(() => {
      students.forEach(student => {
        student.submittedAt = null
        student.excused = undefined
        student.grade = undefined
        student.score = undefined
      })
    })

    it('"Have not yet submitted" does not display students who are excused when selecting "skip excused" checkbox', async () => {
      makeMocks()
      students[2].excused = true
      const {getAllByRole, getByRole, findByLabelText, getByText, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not yet submitted/))

      fireEvent.click(getByTestId('skip-excused-checkbox'))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      expect(studentCells).toHaveLength(4)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(studentCells[3]).toHaveTextContent('Dana Smith')
    })

    it('"Have not yet submitted" does display students who are excused when "skip excused" checkbox is not selected', async () => {
      makeMocks()
      students[2].excused = true
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not yet submitted/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      expect(studentCells).toHaveLength(5)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(studentCells[3]).toHaveTextContent('Dana Smith')
      expect(studentCells[4]).toHaveTextContent('Charlie Xi')
    })

    it('"Have not yet submitted" displays students who have no submitted next to their observers', async () => {
      makeMocks()
      students[2].submittedAt = new Date()
      students[3].submittedAt = new Date()
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not yet submitted/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      const observerCells = tableRows.map(row => row.cells[1])
      // first cell will be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(observerCells[1]).toHaveTextContent('Observer0')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(observerCells[2]).toHaveTextContent('Observer1')
    })

    it('"Have not been graded" does not display students who are excused', async () => {
      makeMocks()
      students[2].excused = true
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell will be the header
      expect(studentCells).toHaveLength(4)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(studentCells[3]).toHaveTextContent('Dana Smith')
    })

    it('"Have not been graded" displays students who do not have a grade', async () => {
      makeMocks()
      // Make a copy of students to avoid modifying the shared array
      const testStudents = [...students]
      testStudents[0].grade = '8'
      testStudents[1].grade = '10'

      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({students: testStudents})} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      await waitFor(() => {
        expect(getByRole('table')).toBeInTheDocument()
      })

      // Find students who don't have grades (should be Charlie Xi and Dana Smith)
      const ungraded = testStudents.filter(student => !student.grade)

      // Get the table rows and verify the correct number of students
      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])

      // Check that we have the header + the ungraded students
      expect(studentCells).toHaveLength(ungraded.length + 1)
      expect(studentCells[0]).toHaveTextContent('Students')

      // Verify that the expected ungraded students are present
      const studentNames = studentCells.slice(1).map(cell => cell.textContent)
      expect(studentNames).toContain('Dana Smith')
      expect(studentNames).toContain('Charlie Xi')
    })
  })
})

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
    // Reset the queryClient before each test to ensure clean state
    beforeEach(() => {
      queryClient.clear()
      // Create a fresh copy of students for each test instead of modifying the shared array
      students.forEach(student => {
        student.submittedAt = null
        student.excused = undefined
        student.grade = undefined
        student.score = undefined
      })
    })
    it('updates the student and observer checkbox counts', async () => {
      // Create a completely isolated copy of students to avoid any shared state
      const testStudents = [
        {
          id: '100',
          name: 'Betty Ford',
          grade: '8',
          redoRequest: false,
          sortableName: 'Ford, Betty',
          score: undefined,
          submittedAt: new Date(),
          excused: false,
          workflowState: 'submitted',
        },
        {
          id: '101',
          name: 'Adam Jones',
          grade: '10',
          redoRequest: false,
          sortableName: 'Jones, Adam',
          score: undefined,
          submittedAt: new Date(),
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
          submittedAt: new Date(),
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
          submittedAt: new Date(),
          excused: false,
          workflowState: 'submitted',
        },
      ]

      // We should have exactly 2 ungraded students (Charlie Xi and Dana Smith)
      const ungradedCount = testStudents.filter(s => s.grade === undefined).length
      expect(ungradedCount).toBe(2)

      // Clear any previous mocks and set up fresh ones
      queryClient.clear()
      makeMocks()

      const {getByLabelText, getByText, findByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({students: testStudents})} />
        </MockedQueryClientProvider>,
      )

      // Initially no students are selected
      expect(await findByTestId('total-student-checkbox')).toHaveAccessibleName('0 Students')
      expect(await findByTestId('total-observer-checkbox')).toHaveAccessibleName('0 Observers')

      // Select "Have not been graded" criteria
      const button = getByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      // Wait for the component to update with the filtered students
      await waitFor(async () => {
        const checkbox = await findByTestId('total-student-checkbox')
        expect(checkbox).toHaveAccessibleName(`${ungradedCount} Students`)
      })
      expect(await findByTestId('total-observer-checkbox')).toHaveAccessibleName('0 Observers')
    })

    describe('"Have submitted"', () => {
      it('renders a student cell if the student has workflowState pending_review and submittedAt', async () => {
        makeMocks()

        students[0].workflowState = 'pending_review'
        students[0].submittedAt = new Date()

        const {getByTestId, findByLabelText, getByText, getAllByRole, getByRole} = render(
          <MockedQueryClientProvider client={queryClient}>
            <MessageStudentsWhoDialog {...makeProps()} />
          </MockedQueryClientProvider>,
        )

        const button = await findByLabelText(/For students who/)
        fireEvent.click(button)
        fireEvent.click(getByText(/Have submitted/))

        // Select "All" radio button
        fireEvent.click(getByTestId('all-students-radio-button'))

        fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
        expect(getByRole('table')).toBeInTheDocument()

        const tableRows = getAllByRole('row') as HTMLTableRowElement[]
        const studentCells = tableRows.map(row => row.cells[0])
        expect(studentCells).toHaveLength(2) // Header + 1 student
        expect(studentCells[1]).toHaveTextContent('Betty Ford')
      })

      it('renders a student cell with workflowState pending_review when "Not Graded" radio button is selected', async () => {
        makeMocks()

        students[0].workflowState = 'pending_review'
        students[0].submittedAt = new Date()

        const {findByLabelText, getByText, getAllByRole, getByRole, getByTestId} = render(
          <MockedQueryClientProvider client={queryClient}>
            <MessageStudentsWhoDialog {...makeProps()} />
          </MockedQueryClientProvider>,
        )

        const button = await findByLabelText(/For students who/)
        fireEvent.click(button)
        fireEvent.click(getByText(/Have submitted/))

        // Select "Not Graded" radio button
        fireEvent.click(getByTestId('not-graded-students-radio-button'))

        fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
        expect(getByRole('table')).toBeInTheDocument()

        const tableRows = getAllByRole('row') as HTMLTableRowElement[]
        const studentCells = tableRows.map(row => row.cells[0])
        expect(studentCells).toHaveLength(2) // Header + 1 student
        expect(studentCells[1]).toHaveTextContent('Betty Ford')
      })

      it('renders a student cell if the student does not have workflowState pending_review and has a grade defined when "Graded" radio button is selected', async () => {
        makeMocks()

        students[0].workflowState = 'graded'
        students[0].submittedAt = new Date()
        students[0].grade = 'A'

        const {findByLabelText, getByText, getAllByRole, getByRole, getByTestId} = render(
          <MockedQueryClientProvider client={queryClient}>
            <MessageStudentsWhoDialog {...makeProps()} />
          </MockedQueryClientProvider>,
        )

        const button = await findByLabelText(/For students who/)
        fireEvent.click(button)
        fireEvent.click(getByText(/Have submitted/))

        // Select "Graded" radio button
        fireEvent.click(getByTestId('graded-students-radio-button'))

        fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
        expect(getByRole('table')).toBeInTheDocument()

        const tableRows = getAllByRole('row') as HTMLTableRowElement[]
        const studentCells = tableRows.map(row => row.cells[0])
        expect(studentCells).toHaveLength(2) // Header + 1 student
        expect(studentCells[1]).toHaveTextContent('Betty Ford')
      })

      it('student radio buttons render when "Have submitted" option is selected', async () => {
        makeMocks()

        const {getByTestId, findByLabelText, getByText} = render(
          <MockedQueryClientProvider client={queryClient}>
            <MessageStudentsWhoDialog {...makeProps()} />
          </MockedQueryClientProvider>,
        )

        const button = await findByLabelText(/For students who/)
        fireEvent.click(button)
        fireEvent.click(getByText(/Have submitted/))

        expect(getByTestId('include-student-radio-group')).toBeInTheDocument()
        expect(getByTestId('all-students-radio-button')).toBeInTheDocument()
        expect(getByTestId('graded-students-radio-button')).toBeInTheDocument()
        expect(getByTestId('not-graded-students-radio-button')).toBeInTheDocument()
      })

      it('displays all students that have submitted the assignment', async () => {
        makeMocks()

        students[0].submittedAt = new Date()
        students[1].submittedAt = new Date()

        const {getAllByRole, getByRole, findByLabelText, getByText, getByTestId} = render(
          <MockedQueryClientProvider client={queryClient}>
            <MessageStudentsWhoDialog {...makeProps()} />
          </MockedQueryClientProvider>,
        )

        const button = await findByLabelText(/For students who/)
        fireEvent.click(button)
        fireEvent.click(getByText(/Have submitted/))

        // Select "All" radio button
        fireEvent.click(getByTestId('all-students-radio-button'))

        fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
        expect(getByRole('table')).toBeInTheDocument()

        const tableRows = getAllByRole('row') as HTMLTableRowElement[]
        const studentCells = tableRows.map(row => row.cells[0])
        expect(studentCells).toHaveLength(3)
        expect(studentCells[0]).toHaveTextContent('Students')
        expect(studentCells[1]).toHaveTextContent('Betty Ford')
        expect(studentCells[2]).toHaveTextContent('Adam Jones')
      })

      it('displays students that have submitted the assignment and have been graded', async () => {
        makeMocks()

        students[0].submittedAt = new Date()
        students[1].submittedAt = new Date()

        students[1].grade = '8'

        const {getAllByRole, getByRole, findByLabelText, getByText, getByTestId} = render(
          <MockedQueryClientProvider client={queryClient}>
            <MessageStudentsWhoDialog {...makeProps()} />
          </MockedQueryClientProvider>,
        )

        const button = await findByLabelText(/For students who/)
        fireEvent.click(button)
        fireEvent.click(getByText(/Have submitted/))

        // Select "Graded" radio button
        fireEvent.click(getByTestId('graded-students-radio-button'))

        fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
        expect(getByRole('table')).toBeInTheDocument()

        const tableRows = getAllByRole('row') as HTMLTableRowElement[]
        const studentCells = tableRows.map(row => row.cells[0])
        expect(studentCells).toHaveLength(2)
        expect(studentCells[0]).toHaveTextContent('Students')
        expect(studentCells[1]).toHaveTextContent('Adam Jones')
      })

      it('displays students that have submitted the assignment but have NOT been graded', async () => {
        makeMocks()

        students[0].submittedAt = new Date()
        students[1].submittedAt = new Date()

        students[1].grade = '8'

        const {getAllByRole, getByRole, findByLabelText, getByText, getByTestId} = render(
          <MockedQueryClientProvider client={queryClient}>
            <MessageStudentsWhoDialog {...makeProps()} />
          </MockedQueryClientProvider>,
        )

        const button = await findByLabelText(/For students who/)
        fireEvent.click(button)
        fireEvent.click(getByText(/Have submitted/))

        // Select "Not Graded" radio button
        fireEvent.click(getByTestId('not-graded-students-radio-button'))

        fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
        expect(getByRole('table')).toBeInTheDocument()

        const tableRows = getAllByRole('row') as HTMLTableRowElement[]
        const studentCells = tableRows.map(row => row.cells[0])
        expect(studentCells).toHaveLength(2)
        expect(studentCells[0]).toHaveTextContent('Students')
        expect(studentCells[1]).toHaveTextContent('Betty Ford')
      })
    })
  })
})

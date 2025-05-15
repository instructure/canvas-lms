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

    it('"Scored more than" displays students who have scored higher than the score inputted', async () => {
      makeMocks()
      students[0].score = 10
      students[1].score = 5.2
      students[2].score = 4
      students[3].score = 0
      const {getAllByRole, getByRole, findByLabelText, getByText, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Scored more than/))
      fireEvent.change(getByTestId('cutoff-input'), {target: {value: '5.1'}})

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

    it('"Scored less than" displays students who have scored lower than the score inputted', async () => {
      makeMocks()
      students[0].score = 10
      students[1].score = 6
      students[2].score = 5.2
      students[3].score = 0
      const {getAllByRole, getByRole, findByLabelText, getByText, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Scored less than/))
      fireEvent.change(getByTestId('cutoff-input'), {target: {value: '5.1'}})

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell will be the header
      expect(studentCells).toHaveLength(2)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Dana Smith')
    })

    it('"Total Grade higher than" displays students who have a total grade higher than grade inputed', async () => {
      makeMocks()
      students[0].currentScore = 80
      students[1].currentScore = 50
      students[2].currentScore = 75
      const {getAllByRole, getByRole, findByLabelText, getByText, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog
            {...makeProps({assignment: null, pointsBasedGradingScheme: false})}
          />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have total grade higher than/))
      fireEvent.change(getByTestId('cutoff-input'), {target: {value: '70'}})

      fireEvent.click(getByTestId('show_all_recipients'))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell with be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(studentCells[2]).toHaveTextContent('Charlie Xi')
    })

    it('"Total Grade lower than" displays students who have a total grade higher than grade inputed', async () => {
      makeMocks()
      students[0].currentScore = 80
      students[1].currentScore = 50
      students[2].currentScore = 75
      const {getAllByRole, getByRole, findByLabelText, getByText, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog
            {...makeProps({assignment: null, pointsBasedGradingScheme: false})}
          />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have total grade lower than/))
      fireEvent.change(getByTestId('cutoff-input'), {target: {value: '70'}})

      fireEvent.click(getByTestId('show_all_recipients'))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      // first cell with be the header
      expect(studentCells).toHaveLength(2)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Adam Jones')
    })

    it('"Reassigned" displays students who have been asked to resubmit to the assignment', async () => {
      makeMocks()
      students[0].redoRequest = true
      students[1].redoRequest = true
      const {getAllByRole, getByRole, getByText, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Reassigned/))

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

    it('"Marked incomplete" displays students who have been marked as "incomplete" on a pass/fail assignment', async () => {
      makeMocks()
      students[0].grade = 'incomplete'
      students[1].grade = 'incomplete'
      const {getAllByRole, getByRole, findByLabelText, getByText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({assignment: passFailAssignment})} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Marked incomplete/))

      fireEvent.click(getByRole('button', {name: 'Show all recipients'}))
      expect(getByRole('table')).toBeInTheDocument()

      const tableRows = getAllByRole('row') as HTMLTableRowElement[]
      const studentCells = tableRows.map(row => row.cells[0])
      const observerCells = tableRows.map(row => row.cells[1])
      // first cell will be the header
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Betty Ford')
      expect(observerCells[1]).toHaveTextContent('Observer0')
      expect(studentCells[2]).toHaveTextContent('Adam Jones')
      expect(observerCells[2]).toHaveTextContent('Observer1')
    })
  })
})

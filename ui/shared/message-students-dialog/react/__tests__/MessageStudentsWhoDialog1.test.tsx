/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {within} from '@testing-library/dom'
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

const ungradedAssignment: CamelizedAssignment = {
  allowedAttempts: 1,
  courseId: '1',
  gradingType: 'not_graded',
  dueAt: null,
  id: '200',
  name: 'A pointless assignment',
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

const unsubmittableAssignment: CamelizedAssignment = {
  allowedAttempts: 3,
  courseId: '1',
  dueAt: new Date().toISOString(),
  gradingType: 'no_submission',
  id: '400',
  name: 'An unsubmittable assignment',
  submissionTypes: ['on_paper'],
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

function allObserverNames() {
  return ['Observer0', 'Observer1']
}

function expectToBeSelected(cell: HTMLElement) {
  const selectedElement = within(cell).getByTestId('item-selected')
  const unselectedElement = within(cell).queryByTestId('item-unselected')
  expect(selectedElement).toBeInTheDocument()
  expect(unselectedElement).not.toBeInTheDocument()
}

function expectToBeUnselected(cell: HTMLElement) {
  const selectedElement = within(cell).queryByTestId('item-selected')
  const unselectedElement = within(cell).getByTestId('item-unselected')
  expect(selectedElement).not.toBeInTheDocument()
  expect(unselectedElement).toBeInTheDocument()
}

describe('MessageStudentsWhoDialog', () => {
  beforeEach(() => {
    fakeENV.setup()
    queryClient.clear()
  })

  afterEach(() => {
    fakeENV.teardown()
  })
  it('hides the list of students and observers initially', async () => {
    makeMocks()

    const {queryByRole} = render(
      <MockedQueryClientProvider client={queryClient}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedQueryClientProvider>,
    )
    await waitFor(() => {
      expect(queryByRole('table')).not.toBeInTheDocument()
    })
  })

  // unskip in EVAL-2535
  it.skip('shows students sorted by sortable name when the table is shown', async () => {
    makeMocks()

    const {getByRole, getAllByRole, findByRole} = render(
      <MockedQueryClientProvider client={queryClient}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedQueryClientProvider>,
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

  // unskip in EVAL-2535
  it.skip('shows observers sorted by the sortable name of the associated user when the table is shown', async () => {
    makeMocks()

    const {findByRole, getByRole, getAllByRole} = render(
      <MockedQueryClientProvider client={queryClient}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedQueryClientProvider>,
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
    expect(observerCells[3]).toHaveTextContent('')
    expect(observerCells[4]).toHaveTextContent('')
  })

  // unskip in EVAL-2535
  it.skip('shows observers in the same cell sorted by the sortable name when observing the same student', async () => {
    makeMocks()

    const {findByRole, getByRole, getAllByRole} = render(
      <MockedQueryClientProvider client={queryClient}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedQueryClientProvider>,
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
    expect(observerCells[2]).toHaveTextContent('')
    expect(observerCells[3]).toHaveTextContent('')
    expect(observerCells[4]).toHaveTextContent('')
  })

  // unskip in EVAL-2535
  it.skip('includes the total number of students in the checkbox label', async () => {
    makeMocks()

    const {findByRole} = render(
      <MockedQueryClientProvider client={queryClient}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedQueryClientProvider>,
    )
    expect(await findByRole('checkbox', {name: /Students/})).toHaveAccessibleName('4 Students')
  })

  // unskip in EVAL-2535
  it.skip('updates total number of students in checkbox label when student is removed from list', async () => {
    makeMocks()

    const {findByRole, findByTestId, findAllByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedQueryClientProvider>,
    )

    expect(await findByTestId('total-student-checkbox')).toHaveAccessibleName('4 Students')

    // Open recipient table
    const button = await findByRole('button', {name: 'Show all recipients'})
    fireEvent.click(button)

    // Select a student cell
    const studentCells = await findAllByTestId('student-pill')
    fireEvent.click(studentCells[0])

    expect(await findByTestId('total-student-checkbox')).toHaveAccessibleName('3 Students')
  })
})

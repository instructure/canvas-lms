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
import {within} from '@testing-library/dom'
import MessageStudentsWhoDialog, {
  type Student,
  type Props as ComponentProps,
  MSWLaunchContext,
} from '../MessageStudentsWhoDialog'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import type {CamelizedAssignment} from '@canvas/grading/grading'
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

  it('includes the total number of observers selected in the checkbox label', async () => {
    makeMocks()

    students.forEach(student => {
      student.submittedAt = null
      student.workflowState = 'unsubmitted'
    })

    const {findByRole} = render(
      <MockedQueryClientProvider client={queryClient}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedQueryClientProvider>,
    )
    const checkbox = await findByRole('checkbox', {name: /Observers/})
    expect(checkbox).toHaveAccessibleName('0 Observers')
    fireEvent.click(checkbox)
    expect(await findByRole('checkbox', {name: /Observers/})).toHaveAccessibleName('2 Observers')
  })

  // unskip in EVAL-2535
  it.skip('updates total number of observers in checkbox label when observer is added to list', async () => {
    makeMocks()

    const {findByRole, findByTestId, findAllByTestId} = render(
      <MockedQueryClientProvider client={queryClient}>
        <MessageStudentsWhoDialog {...makeProps()} />
      </MockedQueryClientProvider>,
    )

    expect(await findByTestId('total-observer-checkbox')).toHaveAccessibleName('0 Observers')

    // Open recipient table
    const button = await findByRole('button', {name: 'Show all recipients'})
    fireEvent.click(button)

    // Select an observer cell
    const observerCells = await findAllByTestId('observer-pill')
    fireEvent.click(observerCells[0])

    expect(await findByTestId('total-observer-checkbox')).toHaveAccessibleName('1 Observers')
  })

  describe('available criteria', () => {
    it('includes score-related options but no "Marked incomplete" option for point-based assignments', async () => {
      makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Have not yet submitted')
      expect(criteriaLabels).toContain('Have submitted')
      expect(criteriaLabels).toContain('Have not been graded')
      expect(criteriaLabels).toContain('Scored more than')
      expect(criteriaLabels).toContain('Scored less than')
      expect(criteriaLabels).not.toContain('Marked incomplete')
    })

    it('includes "Marked incomplete" but no score-related options for pass-fail assignments', async () => {
      makeMocks()

      const {findByLabelText, getAllByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({assignment: passFailAssignment})} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Have not yet submitted')
      expect(criteriaLabels).toContain('Have submitted')
      expect(criteriaLabels).toContain('Have not been graded')
      expect(criteriaLabels).toContain('Marked incomplete')
      expect(criteriaLabels).not.toContain('Scored more than')
      expect(criteriaLabels).not.toContain('Scored less than')
    })

    it('does not include "Marked incomplete" or score-related options for ungraded assignments', async () => {
      makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({assignment: ungradedAssignment})} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Marked incomplete')
      expect(criteriaLabels).not.toContain('Scored more than')
      expect(criteriaLabels).not.toContain('Scored less than')
    })

    it('includes "Have Submitted" and "Have not yet submitted" if the assignment accepts digital submissions', async () => {
      makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Have submitted')
      expect(criteriaLabels).toContain('Have not yet submitted')
    })

    it('does not include "Have Submitted" and "Have not yet submitted" if the assignment does not accept digital submissions', async () => {
      makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({assignment: unsubmittableAssignment})} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Have submitted')
      expect(criteriaLabels).not.toContain('Have not yet submitted')
    })

    it('includes "Reassigned" if the assignment has a due date and allows more than one attempt', async () => {
      makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).toContain('Reassigned')
    })

    it('does not include "Reassigned" if the assignment does not have a due date', async () => {
      makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({assignment: passFailAssignment})} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Reassigned')
    })

    it('does not include "Reassigned" if the assignment does not allow more than one submission', async () => {
      makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({assignment: ungradedAssignment})} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Reassigned')
    })

    it('does not include "Reassigned" if the assignment is on paper', async () => {
      makeMocks()

      const {getAllByRole, findByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({assignment: unsubmittableAssignment})} />
        </MockedQueryClientProvider>,
      )
      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      const criteriaLabels = getAllByRole('option').map(option => option.textContent)
      expect(criteriaLabels).not.toContain('Reassigned')
    })
  })

  describe('cutoff input', () => {
    it('is shown only when "Scored more than" or "Scored less than" is selected', async () => {
      makeMocks()

      const {getByRole, findByTestId, getByTestId, queryByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )
      await waitFor(() => {
        expect(queryByTestId('cutoff-input')).not.toBeInTheDocument()
      })

      const selector = await findByTestId('criterion-dropdown')

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Scored more than'}))
      expect(getByTestId('cutoff-input')).toBeInTheDocument()

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Scored less than'}))
      expect(getByTestId('cutoff-input')).toBeInTheDocument()

      fireEvent.click(selector)
      fireEvent.click(getByRole('option', {name: 'Reassigned'}))
      expect(queryByTestId('cutoff-input')).not.toBeInTheDocument()
    })

    it('foot-note is rendered along with the cutoff-input', async () => {
      makeMocks()

      const {findByTestId, getByText, getByTestId, queryByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      await waitFor(() => {
        expect(queryByTestId('cutoff-footnote')).not.toBeInTheDocument()
      })

      const selector = await findByTestId('criterion-dropdown')

      fireEvent.click(selector)
      fireEvent.click(getByText('Scored more than'))

      expect(getByTestId('cutoff-footnote')).toBeInTheDocument()
    })
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
    it('updates the student and observer checkbox counts', async () => {
      students[0].submittedAt = new Date()
      students[1].submittedAt = new Date()
      students[2].submittedAt = new Date()
      students[3].submittedAt = new Date()

      students[0].grade = '8'
      students[1].grade = '10'
      makeMocks()

      const {getByLabelText, getByText, findByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )
      expect(await findByTestId('total-student-checkbox')).toHaveAccessibleName('0 Students')
      expect(await findByTestId('total-observer-checkbox')).toHaveAccessibleName('0 Observers')

      const button = getByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      expect(await findByTestId('total-student-checkbox')).toHaveAccessibleName('2 Students')
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
      students[0].grade = '8'
      students[1].grade = '10'
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
      expect(studentCells).toHaveLength(3)
      expect(studentCells[0]).toHaveTextContent('Students')
      expect(studentCells[1]).toHaveTextContent('Dana Smith')
      expect(studentCells[2]).toHaveTextContent('Charlie Xi')
    })

    it('"Scored more than" displays students who have scored higher than the score inputted', async () => {
      makeMocks()
      students[0].score = 10
      students[1].score = 5.2
      students[2].score = 4
      students[3].score = 0
      const {getAllByRole, getByRole, getByText, findByLabelText, getByTestId} = render(
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

  // unskip in EVAL-2535
  describe.skip('default subject', () => {
    it('is set to the first criteria that is listed upon opening the modal', async () => {
      makeMocks()
      const {findByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const subjectInput = await findByTestId('subject-input')
      expect(subjectInput).toHaveValue('Submission for A pointed assignment')
    })

    it('is updated when a new criteria is selected', async () => {
      makeMocks()
      const {findByLabelText, getByText, findByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Have not been graded/))

      const subjectInput = await findByTestId('subject-input')
      expect(subjectInput).toHaveValue('No grade for A pointed assignment')
    })

    it('is updated to represent the cutoff input when scored more/less than criteria is selected', async () => {
      makeMocks()
      const {findByLabelText, getByText, findByTestId, getByLabelText} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByLabelText(/For students who/)
      fireEvent.click(button)
      fireEvent.click(getByText(/Scored more than/))

      const subjectInput = await findByTestId('subject-input')
      expect(subjectInput).toHaveValue('Scored more than 0 on A pointed assignment')

      const cutoffInput = await getByLabelText('Enter score cutoff')
      fireEvent.change(cutoffInput, {target: {value: '5'}})

      expect(subjectInput).toHaveValue('Scored more than 5 on A pointed assignment')

      fireEvent.click(button)
      fireEvent.click(getByText(/Scored less than/))

      expect(subjectInput).toHaveValue('Scored less than 5 on A pointed assignment')
    })
  })

  // unskip in EVAL-2535
  describe.skip('students selection', () => {
    beforeEach(() => {
      students[0].submittedAt = null
      students[1].submittedAt = null
      students[2].submittedAt = null
      students[3].submittedAt = null
    })

    it('selects all students by default', async () => {
      makeMocks()
      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const studentCells = students.map(({name}) => getByRole('button', {name}))
      studentCells.forEach(studentCell => expectToBeSelected(studentCell))
    })

    it('sets the students checkbox as checked when all students are selected', async () => {
      makeMocks()
      const {findByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement
      await waitFor(() => {
        expect(checkbox.checked).toBe(true)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the students checkbox as unchecked when all students are unselected', async () => {
      makeMocks()
      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement
      const studentCells = students.map(({name}) => getByRole('button', {name}))
      studentCells.forEach(cell => fireEvent.click(cell))

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the students checkbox as indeterminate when selected students length is between 1 and the total number of students', async () => {
      makeMocks()

      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement
      const studentCells = students.map(({name}) => getByRole('button', {name}))

      fireEvent.click(studentCells[0])

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(true)
      })

      fireEvent.click(studentCells[0])
      studentCells.forEach(cell => fireEvent.click(cell))
      fireEvent.click(studentCells[0])

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(true)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the students checkbox as disabled when the students list is empty', async () => {
      makeMocks()

      const {findByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({students: []})} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Students/})) as HTMLInputElement

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(true)
      })
    })

    it('unselects a selected student by clicking on the student cell', async () => {
      makeMocks()

      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const studentCells = students.map(({name}) => getByRole('button', {name}))

      fireEvent.click(studentCells[0])
      expectToBeUnselected(studentCells[0])
    })

    it('selects an unselected student by clicking on the student cell', async () => {
      makeMocks()

      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const studentCells = students.map(({name}) => getByRole('button', {name}))

      fireEvent.click(studentCells[0])
      fireEvent.click(studentCells[0])

      expectToBeSelected(studentCells[0])
    })
  })

  // unskip in EVAL-2535
  describe.skip('observers selection', () => {
    beforeEach(() => {
      students[0].submittedAt = null
      students[1].submittedAt = null
      students[2].submittedAt = null
      students[3].submittedAt = null
    })

    it('unselects all observers by default', async () => {
      makeMocks()
      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))
      observerCells.forEach(observerCell => expectToBeUnselected(observerCell))
    })

    it('sets the observers checkbox as checked when all observers are selected', async () => {
      makeMocks()
      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))
      observerCells.forEach(cell => fireEvent.click(cell))

      const checkbox = (await findByRole('checkbox', {name: /Observers/})) as HTMLInputElement
      await waitFor(() => {
        expect(checkbox.checked).toBe(true)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the observers checkbox as unchecked when all observers are unselected', async () => {
      makeMocks()
      const {findByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Observers/})) as HTMLInputElement

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the observers checkbox as indeterminate when selected students length is between 1 and the total number of students', async () => {
      makeMocks()

      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Observers/})) as HTMLInputElement
      const observerCells = allObserverNames().map(name => getByRole('button', {name}))

      fireEvent.click(observerCells[0])

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(true)
      })

      fireEvent.click(observerCells[0])
      observerCells.forEach(cell => fireEvent.click(cell))
      fireEvent.click(observerCells[0])

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(true)
        expect(checkbox.disabled).toBe(false)
      })
    })

    it('sets the observers checkbox as disabled when the observer list is empty', async () => {
      makeMocks()
      const newStudent = {
        id: '104',
        name: 'Charlie Brown',
        grade: undefined,
        redoRequest: false,
        sortableName: 'Charlie, Brown',
        score: undefined,
        submittedAt: undefined,
      }
      const {findByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({students: [newStudent]})} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const checkbox = (await findByRole('checkbox', {name: /Observers/})) as HTMLInputElement

      await waitFor(() => {
        expect(checkbox.checked).toBe(false)
        expect(checkbox.indeterminate).toBe(false)
        expect(checkbox.disabled).toBe(true)
      })
    })

    it('unselects a selected observer by clicking on the observer cell', async () => {
      makeMocks()

      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))

      expectToBeUnselected(observerCells[0])
    })

    it('selects an unselected observer by clicking on the observer cell', async () => {
      makeMocks()

      const {findByRole, getByRole} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const button = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(button)

      const observerCells = allObserverNames().map(name => getByRole('button', {name}))

      fireEvent.click(observerCells[0])
      expectToBeSelected(observerCells[0])
    })
  })

  describe('send message button', () => {
    let onSend: jest.Mock<any, any>

    beforeEach(() => {
      onSend = jest.fn()
      students.forEach(student => {
        student.submittedAt = null
      })
    })

    it('does not call onSend when the message body is empty', async () => {
      makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({onSend})} />
        </MockedQueryClientProvider>,
      )

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: ''}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)
      expect(onSend).not.toHaveBeenCalled()
    })

    it('does not call onSend when the message body has only whitespaces', async () => {
      makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({onSend})} />
        </MockedQueryClientProvider>,
      )

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: '   '}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)
      expect(onSend).not.toHaveBeenCalled()
    })

    it('does not call onSend when there are no students/observers selected', async () => {
      makeMocks()

      const {findByLabelText, findByRole, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({onSend})} />
        </MockedQueryClientProvider>,
      )

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'FOO BAR'}})

      const checkbox = (await findByLabelText(/Students/)) as HTMLInputElement;
      fireEvent.click(checkbox)

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)
      expect(onSend).not.toHaveBeenCalled()
    })

    it('calls onSend when the message body is not empty and there is at least one student/observer selected', async () => {
      makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({onSend})} />
        </MockedQueryClientProvider>,
      )

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'FOO BAR'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)
      expect(onSend).toHaveBeenCalled()
    })
  })

  // unskip in EVAL-2535
  describe.skip('onSend', () => {
    let onClose: jest.Mock<any, any>
    let onSend: jest.Mock<any, any>

    beforeEach(() => {
      onClose = jest.fn()
      onSend = jest.fn()
    })

    it('is called with the specified subject', async () => {
      makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({onClose, onSend})} />
        </MockedQueryClientProvider>,
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const subjectInput = getByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'SUBJECT'}})

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'BODY'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)

      expect(onSend).toHaveBeenCalledWith(expect.objectContaining({subject: 'SUBJECT'}))
      expect(onClose).toHaveBeenCalled()
    })

    it('is called with the specified body', async () => {
      makeMocks()

      const {findByRole, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({onClose, onSend})} />
        </MockedQueryClientProvider>,
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const subjectInput = getByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'SUBJECT'}})

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'BODY'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)

      expect(onSend).toHaveBeenCalledWith(expect.objectContaining({body: 'BODY'}))
      expect(onClose).toHaveBeenCalled()
    })

    it('is called with the selected students', async () => {
      makeMocks()

      const {findByRole, getByRole, getByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps({onClose, onSend})} />
        </MockedQueryClientProvider>,
      )

      const recipientsButton = await findByRole('button', {name: 'Show all recipients'})
      fireEvent.click(recipientsButton)

      const studentCells = students.map(({name}) => getByRole('button', {name}))
      fireEvent.click(studentCells[0])

      const subjectInput = getByTestId('subject-input')
      fireEvent.change(subjectInput, {target: {value: 'SUBJECT'}})

      const messageTextArea = getByTestId('message-input')
      fireEvent.change(messageTextArea, {target: {value: 'BODY'}})

      const sendButton = await findByRole('button', {name: 'Send'})
      fireEvent.click(sendButton)

      expect(onSend).toHaveBeenCalledWith(
        expect.objectContaining({recipientsIds: ['101', '102', '103']}),
      )
      expect(onClose).toHaveBeenCalled()
    })
  })
})

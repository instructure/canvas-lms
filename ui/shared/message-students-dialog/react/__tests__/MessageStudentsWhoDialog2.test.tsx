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
})

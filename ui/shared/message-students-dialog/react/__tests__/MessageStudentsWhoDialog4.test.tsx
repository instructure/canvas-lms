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
import {vi} from 'vitest'
import {fireEvent, render} from '@testing-library/react'
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
  newQuizzesAnonymousParticipants: false,
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
    // Reset students to their original state
    students[0].submittedAt = new Date(Date.now())
    students[1].submittedAt = new Date(Date.now())
    students[2].submittedAt = new Date(Date.now())
    students[3].submittedAt = new Date(Date.now())
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('default subject', () => {
    it('is set to the first criteria that is listed upon opening the modal', async () => {
      makeMocks()
      const {findByTestId} = render(
        <MockedQueryClientProvider client={queryClient}>
          <MessageStudentsWhoDialog {...makeProps()} />
        </MockedQueryClientProvider>,
      )

      const subjectInput = await findByTestId('subject-input')
      expect(subjectInput).toHaveValue('No submission for A pointed assignment')
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

      const cutoffInput = await findByLabelText('Cutoff Value')
      fireEvent.change(cutoffInput, {target: {value: '5'}})

      expect(subjectInput).toHaveValue('Scored more than 5 on A pointed assignment')

      fireEvent.click(button)
      fireEvent.click(getByText(/Scored less than/))

      expect(subjectInput).toHaveValue('Scored less than 5 on A pointed assignment')
    })
  })

  // Note: 'students selection' tests moved to MessageStudentsWhoDialogStudentsSelection.test.tsx
  // to reduce test file size and improve parallel execution. These tests were causing CI
  // timeouts when combined with other heavy rendering tests in this file.

  // Note: 'observers selection' tests moved to MessageStudentsWhoDialogObserversSelection.test.tsx
  // to reduce test file size and improve parallel execution. These tests were causing CI
  // timeouts when combined with other heavy rendering tests in this file.

  describe('send message button', () => {
    let onSend: ReturnType<typeof vi.fn>

    beforeEach(() => {
      onSend = vi.fn()
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

      const checkbox = (await findByLabelText(/Students/)) as HTMLInputElement
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

  // Note: 'onSend' tests moved to MessageStudentsWhoDialogOnSend.test.tsx
  // to reduce test file size and improve parallel execution. These tests were causing CI
  // timeouts when combined with other heavy rendering tests in this file.
})

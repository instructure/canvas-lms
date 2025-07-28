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

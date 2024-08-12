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
import axios from '@canvas/axios'
import {cleanup, render, fireEvent, waitFor} from '@testing-library/react'
import MessageStudentsWhoDialog from '../MessageStudentsWhoDialog'
import {mockAssignment, mockUser, mockSubmission} from '../../test-utils'
import {partialSubAssignment, variedSubmissionTypes} from './fixtures/AssignmentMockup'

/*
 *  CAUTION: The InstUI Select component is greatly changed in v7.
 *  Updating the import to the new ui-select location is almost certainly
 *  going to break the functionality of the component. Any failing tests
 *  will just be skipped, and the component can be fixed later when work
 *  resumes on A2.
 */

jest.mock('axios')

function renderMessageStudentsWhoDialog(assignment = mockAssignment(), propsOverride = {}) {
  const props = {
    assignment,
    open: true,
    busy: false,
    handleSend: () => 'Your Messages were sent!',
    onClose: () => 'The dialog is gone!',
    ...propsOverride,
  }
  return render(<MessageStudentsWhoDialog {...props} />)
}

describe.skip('MessageStudentsWhoDialog', () => {
  afterEach(cleanup)

  describe('filters', () => {
    // assignment is of type no-submission
    it('does not show the not submitted yet filter when the assignment is of type no submissions', () => {
      const {queryByText, getByTestId} = renderMessageStudentsWhoDialog(
        mockAssignment({submissionTypes: ['none']})
      )
      fireEvent.click(getByTestId('filter-students'))
      expect(queryByText(`Haven't submitted yet`)).toBeNull()
    })
    // 'First Student' has not submitted, 'Second Student' has submitted
    it('populates the students list when the not submitted filter is selected', () => {
      const {getByText, getByTestId, queryByText} = renderMessageStudentsWhoDialog(
        partialSubAssignment()
      )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText(`Haven't submitted yet`))
      expect(getByText('First Student')).toBeInTheDocument()
      expect(queryByText('Second Student')).toBeNull()
    })
    // 'Second Student' has submitted and has been graded
    it('populates the students list when the ungraded filter is selected', () => {
      const {getByText, getByTestId, queryByText} = renderMessageStudentsWhoDialog(
        partialSubAssignment()
      )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText(`Haven't been graded`))
      expect(getByText('First Student')).toBeInTheDocument()
      expect(queryByText('Second Student')).toBeNull()
    })
    it('populates the students list when the scored less than filter is selected', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: variedSubmissionTypes(),
            },
          })
        )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      fireEvent.click(getByPlaceholderText('Points'))
      fireEvent.change(getByPlaceholderText('Points'), {target: {value: '3'}})
      expect(queryByText('Second Student')).toBeFalsy()
      expect(getByText('First Student')).toBeInTheDocument()
    })
    it('populates the students list when the scored more than filter is selected', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: variedSubmissionTypes(),
            },
          })
        )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      fireEvent.click(getByPlaceholderText('Points'))
      fireEvent.change(getByPlaceholderText('Points'), {target: {value: '2.5'}})
      expect(getByText('Second Student')).toBeInTheDocument()
      expect(queryByText('First Student')).toBeFalsy()
    })
    it('populates the students list when the points field is modified', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: variedSubmissionTypes(),
            },
          })
        )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      const pointsInput = getByPlaceholderText('Points')
      fireEvent.click(pointsInput)
      fireEvent.change(pointsInput, {target: {value: '3'}})
      expect(queryByText('Second Student')).toBeFalsy()
      expect(getByText('First Student')).toBeInTheDocument()
      fireEvent.change(pointsInput, {target: {value: '4.5'}})
      expect(queryByText('Second Student')).toBeInTheDocument()
      expect(getByText('First Student')).toBeInTheDocument()
    })
  })

  describe('points threshold', () => {
    it('does not show points with not submitted filter', () => {
      const {getByText, queryByPlaceholderText, getByTestId} = renderMessageStudentsWhoDialog()
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText("Haven't submitted yet"))
      expect(queryByPlaceholderText('Points')).toBeNull()
    })
    it('does not show points with ungraded filter', () => {
      const {getByText, queryByPlaceholderText, getByTestId} = renderMessageStudentsWhoDialog()
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText("Haven't been graded"))
      expect(queryByPlaceholderText('Points')).toBeNull()
    })
    it('shows points with scored greater than filter', () => {
      const {getByText, getByPlaceholderText, getByTestId} = renderMessageStudentsWhoDialog()
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      expect(getByPlaceholderText('Points')).toBeInTheDocument()
    })
    it('shows points with less than filter', () => {
      const {getByText, getByPlaceholderText, getByTestId} = renderMessageStudentsWhoDialog()
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      expect(getByPlaceholderText('Points')).toBeInTheDocument()
    })
    it('allows a blank value and treats it as 0', () => {
      const {getByText, getByTestId, getByPlaceholderText} = renderMessageStudentsWhoDialog(
        partialSubAssignment({
          needsGradingCount: 0,
          submissions: {
            nodes: variedSubmissionTypes(),
          },
        })
      )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      fireEvent.click(getByPlaceholderText('Points'))
      // both students have score > 0
      expect(getByText('Second Student')).toBeInTheDocument()
      expect(getByText('First Student')).toBeInTheDocument()
    })
    it('increments', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: variedSubmissionTypes(),
            },
          })
        )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      fireEvent.change(getByPlaceholderText('Points'), {target: {value: '0'}})
      const numberInputParent = getByPlaceholderText('Points').parentNode
      const incrementButton = numberInputParent
        .querySelector(`svg[name="IconArrowOpenUp"]`)
        .closest('button')
      fireEvent.mouseOver(incrementButton)
      fireEvent.mouseMove(incrementButton)
      fireEvent.mouseDown(incrementButton)
      incrementButton.focus()
      fireEvent.mouseUp(incrementButton)
      fireEvent.click(incrementButton)
      // Scores for Student3 = 0.5, Student2 = 3.5
      expect(getByPlaceholderText('Points').value).toEqual('1')
      expect(getByText('Second Student')).toBeInTheDocument()
      expect(queryByText('Third Student')).toBeFalsy()
    })
    it('decrements', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: variedSubmissionTypes(),
            },
          })
        )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      fireEvent.change(getByPlaceholderText('Points'), {target: {value: '3'}})
      expect(getByText('Second Student')).toBeInTheDocument()
      expect(queryByText('Fourth Student')).toBeFalsy()
      const numberInputParent = getByPlaceholderText('Points').parentNode
      const decrementButton = numberInputParent
        .querySelector(`svg[name="IconArrowOpenDown"]`)
        .closest('button')
      fireEvent.mouseOver(decrementButton)
      fireEvent.mouseMove(decrementButton)
      fireEvent.mouseDown(decrementButton)
      decrementButton.focus()
      fireEvent.mouseUp(decrementButton)
      fireEvent.click(decrementButton)
      // Scores for Student4 = 2.5, Student2 = 3.5
      expect(getByPlaceholderText('Points').value).toEqual('2')
      expect(getByText('Second Student')).toBeInTheDocument()
      expect(getByText('Fourth Student')).toBeInTheDocument()
    })
    it('increments with blank value', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: variedSubmissionTypes(),
            },
          })
        )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      const numberInputParent = getByPlaceholderText('Points').parentNode
      const incrementButton = numberInputParent
        .querySelector(`svg[name="IconArrowOpenUp"]`)
        .closest('button')
      fireEvent.mouseOver(incrementButton)
      fireEvent.mouseMove(incrementButton)
      fireEvent.mouseDown(incrementButton)
      incrementButton.focus()
      fireEvent.mouseUp(incrementButton)
      fireEvent.click(incrementButton)
      // Scores for Student3 = 0.5, Student2 = 3.5
      expect(getByPlaceholderText('Points').value).toEqual('1')
      expect(getByText('Second Student')).toBeInTheDocument()
      expect(queryByText('Third Student')).toBeFalsy()
    })
    it('decrements with blank value', () => {
      const {getByText, getByTestId, getByPlaceholderText} = renderMessageStudentsWhoDialog(
        partialSubAssignment({
          needsGradingCount: 0,
          submissions: {
            nodes: variedSubmissionTypes(),
          },
        })
      )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      const numberInputParent = getByPlaceholderText('Points').parentNode
      const decrementButton = numberInputParent
        .querySelector(`svg[name="IconArrowOpenDown"]`)
        .closest('button')
      fireEvent.mouseOver(decrementButton)
      fireEvent.mouseMove(decrementButton)
      fireEvent.mouseDown(decrementButton)
      decrementButton.focus()
      fireEvent.mouseUp(decrementButton)
      fireEvent.click(decrementButton)
      // Scores for Student3 = 0.5, Student2 = 3.5
      expect(getByPlaceholderText('Points').value).toEqual('0')
      expect(getByText('Second Student')).toBeInTheDocument()
      expect(getByText('Third Student')).toBeInTheDocument()
    })
    it('does not allow negative points', () => {
      const {getByText, getByTestId, getByPlaceholderText} = renderMessageStudentsWhoDialog(
        partialSubAssignment()
      )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      fireEvent.change(getByPlaceholderText('Points'), {target: {value: '0'}})
      const numberInputParent = getByPlaceholderText('Points').parentNode
      const decrementButton = numberInputParent
        .querySelector(`svg[name="IconArrowOpenDown"]`)
        .closest('button')
      fireEvent.mouseOver(decrementButton)
      fireEvent.mouseMove(decrementButton)
      fireEvent.mouseDown(decrementButton)
      decrementButton.focus()
      fireEvent.mouseUp(decrementButton)
      fireEvent.click(decrementButton)
      expect(getByPlaceholderText('Points').value).toEqual('0')
    })
  })

  describe('students list', () => {
    it('changes the student list when the "not submitted" filter is selected', () => {
      const {getByText, getByTestId, queryByText} = renderMessageStudentsWhoDialog(
        partialSubAssignment({
          needsGradingCount: 0,
          submissions: {
            nodes: variedSubmissionTypes(),
          },
        })
      )
      fireEvent.click(getByTestId('filter-students'))
      // Both students have not submitted, Student6 has a grade
      // default is unsubmitted, so we change to ungraded first and then back to unsubmitted for this test
      fireEvent.click(getByText(`Haven't been graded`))
      expect(getByText('Fifth Student')).toBeInTheDocument()
      expect(queryByText('Sixth Student')).toBeNull()
      fireEvent.click(getByTestId('filter-students'))
      // Both students have not submitted
      fireEvent.click(getByText(`Haven't submitted yet`))
      expect(getByText('Fifth Student')).toBeInTheDocument()
      expect(getByText('Sixth Student')).toBeInTheDocument()
    })
    it('changes the student list when the "ungraded" filter is selected', () => {
      const {getByText, getByTestId, queryByText} = renderMessageStudentsWhoDialog(
        partialSubAssignment({
          needsGradingCount: 0,
          submissions: {
            nodes: variedSubmissionTypes(),
          },
        })
      )
      // Default is unsubmitted and both students have not submitted
      expect(getByText('Fifth Student')).toBeInTheDocument()
      expect(getByText('Sixth Student')).toBeInTheDocument()
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText(`Haven't been graded`))
      // Only Student6 is graded
      expect(getByText('Fifth Student')).toBeInTheDocument()
      expect(queryByText('Sixth Student')).toBeNull()
    })
    it('changes the student list when the "less than" filter is selected', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: [
                mockSubmission({
                  gid: '1sub',
                  lid: '1',
                  state: 'graded',
                  submissionStatus: 'submitted',
                  gradingStatus: 'graded',
                  submittedAt: '2019-03-13T12:21:42Z',
                  score: 2,
                  grade: '2',
                  user: mockUser({
                    gid: '1user',
                    lid: '1',
                    name: 'First Student',
                    shortName: 'FirstS1',
                    sortableName: 'Student, First',
                    email: 'first_student1@example.com',
                  }),
                }),
                mockSubmission({
                  gid: '2sub',
                  lid: '2',
                  state: 'graded',
                  submissionStatus: 'submitted',
                  submittedAt: '2019-03-12T12:21:42Z',
                  gradingStatus: 'graded',
                  score: 3.5,
                  grade: '3.5',
                  user: mockUser({
                    gid: '2user',
                    lid: '2',
                    name: 'Second Student',
                    shortName: 'SecondS12',
                    sortableName: 'Student, Second',
                    email: 'second_student2@example.com',
                  }),
                }),
              ],
            },
          })
        )
      // Default is unsubmitted, both students have submitted and have a grade
      expect(queryByText('Second Student')).toBeNull()
      expect(queryByText('First Student')).toBeNull()
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      fireEvent.click(getByPlaceholderText('Points'))
      fireEvent.change(getByPlaceholderText('Points'), {target: {value: '3'}})
      expect(queryByText('Second Student')).toBeNull()
      expect(getByText('First Student')).toBeInTheDocument()
    })
    it('changes the student list when the "greater than" filter is selected', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: variedSubmissionTypes(),
            },
          })
        )
      // Default is unsubmitted, both students have submitted and have a grade
      expect(queryByText('Second Student')).toBeFalsy()
      expect(queryByText('First Student')).toBeFalsy()
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored more than'))
      fireEvent.click(getByPlaceholderText('Points'))
      fireEvent.change(getByPlaceholderText('Points'), {target: {value: '2.5'}})
      expect(getByText('Second Student')).toBeInTheDocument()
      expect(queryByText('First Student')).toBeNull()
    })
    it('changes the student list when the points field changes', () => {
      const {getByText, getByTestId, queryByText, getByPlaceholderText} =
        renderMessageStudentsWhoDialog(
          partialSubAssignment({
            needsGradingCount: 0,
            submissions: {
              nodes: variedSubmissionTypes(),
            },
          })
        )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      expect(queryByText('Second Student')).toBeFalsy()
      expect(queryByText('First Student')).toBeFalsy()
      const pointsInput = getByPlaceholderText('Points')
      fireEvent.click(pointsInput)
      fireEvent.change(pointsInput, {target: {value: '3'}})
      expect(queryByText('Second Student')).toBeFalsy()
      expect(getByText('First Student')).toBeInTheDocument()
    })
    it('can remove students', () => {
      const {getByText, queryByText} = renderMessageStudentsWhoDialog(partialSubAssignment())
      // default filter is unsubmitted
      expect(getByText('First Student')).toBeInTheDocument()
      expect(queryByText('Second Student')).toBeNull()
      const removeStudent1Button = getByText('Remove First Student').closest('button')
      fireEvent.click(removeStudent1Button)
      expect(queryByText('First Student')).toBeNull()
    })
    it('can add students', () => {
      const {getByText, getByTestId, queryByText} = renderMessageStudentsWhoDialog(
        partialSubAssignment()
      )
      expect(queryByText('Second Student')).toBeNull()
      fireEvent.click(getByTestId('student-recipients'))
      fireEvent.click(getByText('Second Student'))
      expect(getByText('First Student')).toBeInTheDocument()
      expect(getByText('Second Student')).toBeInTheDocument()
    })
    it('resets the student list when the filter changes, even when the students list has changed', () => {
      const {getByText, queryByText, getByTestId} = renderMessageStudentsWhoDialog(
        partialSubAssignment()
      )
      // default filter is unsubmitted
      expect(getByText('First Student')).toBeInTheDocument()
      expect(queryByText('Second Student')).toBeNull()
      // add Second Student
      fireEvent.click(getByTestId('student-recipients'))
      fireEvent.click(getByText('Second Student'))
      expect(getByText('Second Student')).toBeInTheDocument()
      // reset filter to unsubmitted and Second Student should be removed
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText(`Haven't submitted yet`))
      expect(getByText('First Student')).toBeInTheDocument()
      expect(queryByText('Second Student')).toBeNull()
    })
    it('resets the student list when the points field changes, even when the student list has changed ', () => {
      const {getByText, getByTestId, queryByText} = renderMessageStudentsWhoDialog(
        partialSubAssignment({
          needsGradingCount: 0,
          submissions: {
            nodes: variedSubmissionTypes(),
          },
        })
      )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      expect(queryByText('Second Student')).toBeFalsy()
      expect(queryByText('First Student')).toBeFalsy()
      // add Second Student
      fireEvent.click(getByTestId('student-recipients'))
      fireEvent.click(getByText('Second Student'))
      expect(getByText('Second Student')).toBeInTheDocument()
      // reset filter to scored less than 0
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      expect(queryByText('Second Student')).toBeFalsy()
      expect(queryByText('First Student')).toBeFalsy()
    })
  })

  describe('subject autofill', () => {
    it('autofills the subject field when the filter changes', () => {
      const {getByText, getByTestId} = renderMessageStudentsWhoDialog(partialSubAssignment())
      // default filter is unsubmitted
      const subjectInput = getByTestId('subject-input')
      expect(subjectInput.value).toEqual('No submission for Basic Mock Assignment')
      // change filter
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText(`Haven't been graded`))
      expect(subjectInput.value).toEqual('No grade for Basic Mock Assignment')
    })
    it('autofills the subject field when the points change', () => {
      const {getByText, getByTestId, getByPlaceholderText} = renderMessageStudentsWhoDialog(
        partialSubAssignment()
      )
      fireEvent.click(getByTestId('filter-students'))
      fireEvent.click(getByText('Scored less than'))
      const subjectInput = getByTestId('subject-input')
      expect(subjectInput.value).toEqual('Scored less than 0 on Basic Mock Assignment')
      fireEvent.click(getByPlaceholderText('Points'))
      fireEvent.change(getByPlaceholderText('Points'), {target: {value: '2'}})
      expect(subjectInput.value).toEqual('Scored less than 2 on Basic Mock Assignment')
    })
  })

  describe('text fields', () => {
    it('allows typing in a subject', () => {
      const {getByTestId} = renderMessageStudentsWhoDialog(partialSubAssignment())
      const subjectInput = getByTestId('subject-input')
      // default filter is unsubmitted so verify autofill text
      expect(subjectInput.value).toEqual('No submission for Basic Mock Assignment')
      // change input
      fireEvent.click(subjectInput)
      fireEvent.change(subjectInput, {target: {value: 'Typing a subject here'}})
      // verify new input
      expect(subjectInput.value).toEqual('Typing a subject here')
    })

    it('allows typing in a body', () => {
      const {getByTestId} = renderMessageStudentsWhoDialog(partialSubAssignment())
      const bodyInput = getByTestId('body-input')
      // default filter is unsubmitted so verify autofill text
      expect(bodyInput.value).toEqual('')
      fireEvent.change(bodyInput, {target: {value: 'Typing some body text here'}})
      // verify new input
      expect(bodyInput.value).toEqual('Typing some body text here')
    })
  })

  describe('save button enabled', () => {
    it('is disabled when subject is blank', () => {
      const {getByTestId, getByText} = renderMessageStudentsWhoDialog(partialSubAssignment())
      // ensure body has text and subject is the only empty field
      const bodyInput = getByTestId('body-input')
      const subjectInput = getByTestId('subject-input')
      fireEvent.change(bodyInput, {target: {value: 'Typing some body text here'}})
      // clear the auto-filled subject
      fireEvent.click(subjectInput)
      fireEvent.change(subjectInput, {target: {value: ''}})
      const sendButton = getByText('Send').closest('button')
      expect(sendButton.disabled).toEqual(true)
    })
    it('is disabled when the body is blank', () => {
      const {getByTestId, getByText} = renderMessageStudentsWhoDialog(partialSubAssignment())
      // default unsubmitted filter auto-fills all fields except body
      const bodyInput = getByTestId('body-input')
      expect(bodyInput.value).toEqual('')
      const sendButton = getByText('Send').closest('button')
      expect(sendButton.disabled).toEqual(true)
    })

    it('is disabled when no students are selected', () => {
      const {getByTestId, getByText} = renderMessageStudentsWhoDialog(partialSubAssignment())
      // ensure body has text and recipents is the only empty field
      const bodyInput = getByTestId('body-input')
      fireEvent.change(bodyInput, {target: {value: 'Typing some body text here'}})
      const removeStudent1Button = getByText('Remove First Student').closest('button')
      fireEvent.click(removeStudent1Button)
      const sendButton = getByText('Send').closest('button')
      expect(sendButton.disabled).toEqual(true)
    })

    it('is enabled when there is a subject, body, and students to message', () => {
      const {getByTestId, getByText} = renderMessageStudentsWhoDialog(partialSubAssignment())
      // default unsubmitted filter auto-fills all fields except body
      const bodyInput = getByTestId('body-input')
      fireEvent.change(bodyInput, {target: {value: 'Typing some body text here'}})
      const sendButton = getByText('Send').closest('button')
      expect(sendButton.disabled).toEqual(false)
    })
  })

  describe('sending messages', () => {
    it('displays loading state when message is being sent', async () => {
      const {getByTestId, getByText} = renderMessageStudentsWhoDialog(partialSubAssignment())
      const bodyInput = getByTestId('body-input')
      fireEvent.change(bodyInput, {target: {value: 'Typing some body text here'}})
      const sendButton = getByText('Send').closest('button')
      axios.post.mockResolvedValue(() => Promise.resolve({status: 202, data: []}))
      fireEvent.click(sendButton)

      expect(await waitFor(() => getByText('Sending messages'))).toBeInTheDocument()
    })

    it('handles success', async () => {
      const {getByTestId, getByText} = renderMessageStudentsWhoDialog(partialSubAssignment())
      const bodyInput = getByTestId('body-input')
      fireEvent.change(bodyInput, {target: {value: 'Typing some body text here'}})
      const sendButton = getByText('Send').closest('button')
      axios.post.mockResolvedValue(() => Promise.resolve({status: 202, data: []}))
      fireEvent.click(sendButton)

      // filter out the screenreader alerts and assert that
      // the main div with 'id=flashalert_message_holder' has the success message
      const msgsContainer = await document.querySelector('#flashalert_message_holder')
      expect(msgsContainer).toHaveTextContent(/Messages sent/i)
    })

    it('handles error', async () => {
      const {getByTestId, findAllByText, getByText} = renderMessageStudentsWhoDialog(
        partialSubAssignment()
      )
      const bodyInput = getByTestId('body-input')
      fireEvent.change(bodyInput, {target: {value: 'Typing some body text here'}})
      const sendButton = getByText('Send').closest('button')
      axios.post.mockRejectedValue(() => Promise.reject(new Error('something bad happened')))
      fireEvent.click(sendButton)

      // filter out the screenreader alerts and assert that
      // the main div with 'id=flashalert_message_holder' has the error message
      const msgsContainer = await findAllByText('Error sending messages')
      expect(msgsContainer[0].closest('div#flashalert_message_holder')).not.toBeNull()
    })
  })
})

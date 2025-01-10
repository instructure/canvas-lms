/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {fireEvent, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import {Assignment} from '../../../../graphql/Assignment'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {GroupSet} from '../../../../graphql/GroupSet'
import {REPLY_TO_ENTRY, REPLY_TO_TOPIC} from '../../../util/constants'
import DiscussionTopicForm, {isGuidDataValid, getAbGuidArray} from '../DiscussionTopicForm'

jest.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm', () => {
  const setup = ({
    isEditing = false,
    currentDiscussionTopic = {},
    assignmentGroups = [],
    isStudent = false,
    sections = [],
    groupCategories = [],
    onSubmit = () => {},
    isGroupContext = false,
  } = {}) => {
    return render(
      <DiscussionTopicForm
        assignmentGroups={assignmentGroups}
        isEditing={isEditing}
        currentDiscussionTopic={currentDiscussionTopic}
        isStudent={isStudent}
        sections={sections}
        groupCategories={groupCategories}
        onSubmit={onSubmit}
        apolloClient={null}
        studentEnrollments={[]}
        isGroupContext={isGroupContext}
      />,
    )
  }

  beforeEach(() => {
    window.ENV = {
      DISCUSSION_TOPIC: {
        PERMISSIONS: {
          CAN_ATTACH: true,
          CAN_MODERATE: true,
          CAN_CREATE_ASSIGNMENT: true,
          CAN_SET_GROUP: true,
          CAN_MANAGE_ASSIGN_TO_GRADED: true,
          CAN_MANAGE_ASSIGN_TO_UNGRADED: true,
        },
        ATTRIBUTES: {},
      },
      FEATURES: {},
      PERMISSIONS: {},
      allow_student_anonymous_discussion_topics: false,
      USAGE_RIGHTS_REQUIRED: false,
      K5_HOMEROOM_COURSE: false,
      current_user: {},
      STUDENT_PLANNER_ENABLED: true,
      DISCUSSION_CHECKPOINTS_ENABLED: true,
      ASSIGNMENT_EDIT_PLACEMENT_NOT_ON_ANNOUNCEMENTS: false,
      context_is_not_group: true,
      RESTRICT_QUANTITATIVE_DATA: false,
    }
  })

  describe('Graded', () => {
    it('does not allow the automatic peer review per student input to go below 1', () => {
      const {getByTestId, getByLabelText} = setup()

      getByLabelText('Graded').click()
      getByLabelText('Automatically assign').click()
      const automaticReviewsInput = getByTestId('peer-review-count-input')
      expect(automaticReviewsInput.value).toBe('1')

      fireEvent.click(automaticReviewsInput)

      fireEvent.keyDown(automaticReviewsInput, {keyCode: 40})
      expect(automaticReviewsInput.value).toBe('1')
    })

    describe('validate abGuid for Mastery Connect', () => {
      it('returns the ab_guid array from the event data', () => {
        setup()

        const mockEvent = {
          data: {
            subject: 'assignment.set_ab_guid',
            data: ['1E20776E-7053-11DF-8EBF-BE719DFF4B22', '1E20776E-7053-0000-0000-BE719DFF4B22'],
          },
        }

        expect(getAbGuidArray(mockEvent)).toEqual([
          '1E20776E-7053-11DF-8EBF-BE719DFF4B22',
          '1E20776E-7053-0000-0000-BE719DFF4B22',
        ])
      })

      it('isGuidDataValid returns true if ab_guid format and subject are correct', () => {
        setup()

        const mockEvent = {
          data: {
            subject: 'assignment.set_ab_guid',
            data: ['1E20776E-7053-11DF-8EBF-BE719DFF4B22'],
          },
        }

        expect(isGuidDataValid(mockEvent)).toEqual(true)
      })

      it('isGuidDataValid returns false if subject is not assignment.set_ab_guid', () => {
        setup()

        const mockEvent = {
          data: {
            subject: 'not right subject',
            data: ['1E20776E-7053-11DF-8EBF-BE719DFF4B22'],
          },
        }

        expect(isGuidDataValid(mockEvent)).toBe(false)
      })

      it('isGuidDataValid returns false if at least one of the ab_guids in the array is not formatted correctly', () => {
        setup()

        const mockEvent = {
          data: {
            subject: 'assignment.set_ab_guid',
            data: ['not right format', '1E20776E-7053-11DF-8EBF-BE719DFF4B22'],
          },
        }

        expect(isGuidDataValid(mockEvent)).toBe(false)
      })
    })

    describe('Course Pacing', () => {
      it('can successfully validate the form when course pacing is enabled (custom ItemAssignToTray validation is skipped, as there is no related input is expected)', () => {
        window.ENV.CONTEXT_TYPE = 'Group'
        window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
        window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.in_paced_course = true

        const onSubmit = jest.fn()
        const {getByText, getByPlaceholderText} = setup({
          onSubmit,
          currentDiscussionTopic: DiscussionTopic.mock({
            assignment: Assignment.mock({
              hasSubAssignments: true,
            }),
            groupSet: GroupSet.mock(),
            canGroup: true,
          }),
        })
        const saveButton = getByText('Save')
        fireEvent.input(getByPlaceholderText('Topic Title'), {target: {value: 'a title'}})
        saveButton.click()
        expect(onSubmit).toHaveBeenCalled()
      })
    })

    describe('Checkpoints', () => {
      it('toggles the checkpoints checkbox when clicked', () => {
        const {getByTestId, getByLabelText} = setup()

        getByLabelText('Graded').click()

        const checkbox = getByTestId('checkpoints-checkbox')
        checkbox.click()
        expect(checkbox.checked).toBe(true)

        checkbox.click()
        expect(checkbox.checked).toBe(false)
      })

      it('unchecks the checkpoints checkbox when graded is unchecked', () => {
        const {getByTestId, getByLabelText} = setup()

        getByLabelText('Graded').click()
        getByTestId('checkpoints-checkbox').click()
        expect(getByTestId('checkpoints-checkbox').checked).toBe(true)

        // 1st graded click will uncheck checkpoints. but it also hides from document.
        // 2nd graded click will render checkpoints, notice its unchecked.
        getByLabelText('Graded').click()
        getByLabelText('Graded').click()
        expect(getByTestId('checkpoints-checkbox').checked).toBe(false)
      })

      it('renders the checkpoints checkbox as selected when there are existing checkpoints', () => {
        const {getByTestId} = setup({
          currentDiscussionTopic: DiscussionTopic.mock({
            assignment: Assignment.mock({hasSubAssignments: true}),
          }),
        })
        const checkbox = getByTestId('checkpoints-checkbox')
        expect(checkbox.checked).toBe(true)
      })
      describe('Checkpoints Settings', () => {
        let getByTestId, getByLabelText

        const setupCheckpoints = setupFunction => {
          const discussionTopicSetup = setupFunction

          getByTestId = discussionTopicSetup.getByTestId
          getByLabelText = discussionTopicSetup.getByLabelText

          getByLabelText('Graded').click()

          const checkbox = getByTestId('checkpoints-checkbox')
          checkbox.click()
        }

        describe('Additional Replies Required', () => {
          it('increments and decrements the checkpoints settings additional replies required entry field', () => {
            setupCheckpoints(setup())

            const numberInputReplyToEntryRequiredCount = getByTestId(
              'reply-to-entry-required-count',
            )
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

            fireEvent.click(numberInputReplyToEntryRequiredCount)

            fireEvent.keyDown(numberInputReplyToEntryRequiredCount, {keyCode: 38})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('2')

            fireEvent.keyDown(numberInputReplyToEntryRequiredCount, {keyCode: 40})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')
          })
          it('does not allow incrementing or decrementing if required count is not in the allowed range', () => {
            setupCheckpoints(setup())

            const numberInputReplyToEntryRequiredCount = getByTestId(
              'reply-to-entry-required-count',
            )
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

            fireEvent.click(numberInputReplyToEntryRequiredCount)

            fireEvent.keyDown(numberInputReplyToEntryRequiredCount, {keyCode: 40})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

            fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: '10'}})

            fireEvent.keyDown(numberInputReplyToEntryRequiredCount, {keyCode: 38})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('10')
          })
          it('allows input to be changed if the required count falls within the allowed range', () => {
            setupCheckpoints(setup())

            const numberInputReplyToEntryRequiredCount = getByTestId(
              'reply-to-entry-required-count',
            )
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

            fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: '6'}})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('6')
          })
          it('does not allow input to be changed if the required count falls outside the allowed range', () => {
            setupCheckpoints(setup())

            const numberInputReplyToEntryRequiredCount = getByTestId(
              'reply-to-entry-required-count',
            )
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

            fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: '11'}})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

            fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: '0'}})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')
          })
          it('reverts to minimum required count value if user has backspaced and leaves the input field', () => {
            setupCheckpoints(setup())

            const numberInputReplyToEntryRequiredCount = getByTestId(
              'reply-to-entry-required-count',
            )
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

            fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: ''}})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('0')

            fireEvent.blur(numberInputReplyToEntryRequiredCount)
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')
          })
        })
        it('sets the correct checkpoint settings values when there are existing checkpoints', () => {
          const {getByTestId} = setup({
            currentDiscussionTopic: DiscussionTopic.mock({
              replyToEntryRequiredCount: 5,
              assignment: Assignment.mock({
                hasSubAssignments: true,
                checkpoints: [
                  {
                    dueAt: null,
                    name: 'checkpoint discussion',
                    onlyVisibleToOverrides: false,
                    pointsPossible: 6,
                    tag: REPLY_TO_TOPIC,
                  },
                  {
                    dueAt: null,
                    name: 'checkpoint discussion',
                    onlyVisibleToOverrides: false,
                    pointsPossible: 7,
                    tag: REPLY_TO_ENTRY,
                  },
                ],
              }),
            }),
          })

          const numberInputReplyToTopic = getByTestId('points-possible-input-reply-to-topic')
          expect(numberInputReplyToTopic.value).toBe('6')
          const numberInputReplyToEntry = getByTestId('points-possible-input-reply-to-entry')
          expect(numberInputReplyToEntry.value).toBe('7')
          const numberInputAdditionalRepliesRequired = getByTestId('reply-to-entry-required-count')
          expect(numberInputAdditionalRepliesRequired.value).toBe('5')
        })
      })
    })
  })
})

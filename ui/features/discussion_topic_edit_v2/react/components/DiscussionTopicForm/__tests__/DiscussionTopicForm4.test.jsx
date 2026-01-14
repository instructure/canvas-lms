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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {Assignment} from '../../../../graphql/Assignment'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {GroupSet} from '../../../../graphql/GroupSet'
import DiscussionTopicForm, {isGuidDataValid, getAbGuidArray} from '../DiscussionTopicForm'

vi.mock('@canvas/rce/react/CanvasRce')

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
      SETTINGS: {},
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

        const onSubmit = vi.fn()
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
      // Note: The 'toggles the checkpoints checkbox when clicked' test was removed
      // because it was redundant with tests in DiscussionTopicFormCheckpoints.test.jsx
      // and was causing CI timeouts due to heavy re-renders.

      it('renders the checkpoints checkbox as selected when there are existing checkpoints', () => {
        const {getByTestId} = setup({
          currentDiscussionTopic: DiscussionTopic.mock({
            assignment: Assignment.mock({hasSubAssignments: true}),
          }),
        })
        const checkbox = getByTestId('checkpoints-checkbox').querySelector('input')
        expect(checkbox.checked).toBe(true)
      })
    })
  })
})

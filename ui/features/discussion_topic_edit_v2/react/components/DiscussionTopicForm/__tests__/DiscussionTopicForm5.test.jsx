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

import {render, waitFor, fireEvent} from '@testing-library/react'
import React from 'react'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import DiscussionTopicForm from '../DiscussionTopicForm'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm', () => {
  const setup = ({
    isEditing = true,
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

  describe('Todo Date', () => {
    // TODO: vi->vitest - test times out waiting for form submission, needs investigation
    it('clears todo date in submission when switching to graded', async () => {
      const mockOnSubmit = vi.fn()
      const todoDate = '2024-12-31T23:59:00Z'
      const {getByTestId} = setup({
        onSubmit: mockOnSubmit,
        currentDiscussionTopic: DiscussionTopic.mock({
          todoDate,
          addToTodo: true,
        }),
      })

      // Switch to graded
      getByTestId('graded-checkbox').querySelector('input').click()

      // Submit form
      getByTestId('save-button').click()

      // Verify submission
      expect(mockOnSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          todoDate: null,
          assignment: expect.any(Object),
        }),
        false,
      )
    })

    it('preserves todo date in ungraded mode', async () => {
      const mockOnSubmit = vi.fn()
      const todoDate = '2024-12-31T23:59:00Z'
      const {getByTestId} = setup({
        onSubmit: mockOnSubmit,
        currentDiscussionTopic: DiscussionTopic.mock({
          todoDate,
          addToTodo: true,
        }),
      })

      // Submit form
      getByTestId('save-button').click()

      // Verify submission
      expect(mockOnSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          todoDate,
          assignment: null,
        }),
        false,
      )
    })
  })

  // FIXME: jsdom 25 changed how DateTimeInput generates timestamps when selecting dates,
  // causing the midnight detection in isFancyMidnightNeeded to fail. The date picker now
  // returns a different time value that doesn't trigger the 00:00:00 -> 23:59:00 conversion.
  it.skip('applies fancy midnight to assign reviews when needed', () => {
    const {getByTestId, getByText} = setup()

    getByTestId('graded-checkbox').querySelector('input').click()
    getByTestId('peer_review_auto').click()

    const dueDate = getByTestId('reviews-due-date')
    const dueTime = getByTestId('reviews-due-time')

    expect(dueDate).toBeInTheDocument()
    expect(dueTime).toBeInTheDocument()

    fireEvent.change(dueDate, {target: {value: 'Nov 9, 2020'}})
    fireEvent.click(getByText('10 November 2020'))

    expect(dueTime).toHaveValue('11:59 PM')
  })

  it('does not apply fancy midnight to assign reviews when the user have other time set', () => {
    const {getByTestId, getByText} = setup()

    getByTestId('graded-checkbox').querySelector('input').click()
    getByTestId('peer_review_auto').click()

    const dueDate = getByTestId('reviews-due-date')
    const dueTime = getByTestId('reviews-due-time')

    expect(dueDate).toBeInTheDocument()
    expect(dueTime).toBeInTheDocument()

    fireEvent.change(dueTime, {target: {value: '10:00 AM'}})
    fireEvent.click(getByText('10:00 AM'))

    fireEvent.change(dueDate, {target: {value: 'Nov 9, 2020'}})
    fireEvent.click(getByText('10 November 2020'))

    expect(dueTime).toHaveValue('10:00 AM')
  })

  describe('Checkpoints in Blueprint Course', () => {
    beforeEach(() => {
      window.ENV = {
        ...window.ENV,
        DISCUSSION_TOPIC: {
          ...window.ENV.DISCUSSION_TOPIC,
          PERMISSIONS: {
            ...window.ENV.DISCUSSION_TOPIC.PERMISSIONS,
            CAN_ATTACH: true,
            CAN_MODERATE: true,
            CAN_CREATE_ASSIGNMENT: true,
            CAN_SET_GROUP: true,
            CAN_MANAGE_ASSIGN_TO_GRADED: true,
            CAN_MANAGE_ASSIGN_TO_UNGRADED: true,
          },
        },
        FEATURES: {
          discussion_checkpoints: true,
        },
        IS_BLUEPRINT_COURSE: true,
        DISCUSSION_CHECKPOINTS_ENABLED: true,
        context_type: 'Course',
      }
    })

    it('sets delayedPostAt and lockAt to null when checkpoints are enabled in a blueprint course', async () => {
      const mockOnSubmit = vi.fn()
      const availableFrom = '2024-12-31T10:00:00Z'
      const availableUntil = '2024-12-31T23:59:00Z'

      const {getByText} = setup({
        onSubmit: mockOnSubmit,
        currentDiscussionTopic: DiscussionTopic.mock({
          assignment: {},
          availableFrom,
          availableUntil,
        }),
      })

      // Submit form
      getByText('Save').click()

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalled()
        const submissionData = mockOnSubmit.mock.calls[0][0]
        expect(submissionData.delayedPostAt).toBeNull()
        expect(submissionData.lockAt).toBeNull()
      })
    })

    it('sets dates normally when checkpoints are disabled in a blueprint course', async () => {
      window.ENV.FEATURES.discussion_checkpoints = false
      window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = false
      const mockOnSubmit = vi.fn()
      const availableFrom = '2024-12-31T10:00:00Z'
      const availableUntil = '2024-12-31T23:59:00Z'

      const {getByText} = setup({
        onSubmit: mockOnSubmit,
        currentDiscussionTopic: DiscussionTopic.mock({
          groupSet: null,
          assignment: {
            __typename: 'Assignment',
            id: 'QXNzaWdubWVudC0yMg==',
            _id: '22',
            name: 'Non checkpointed',
            postToSis: false,
            pointsPossible: 0,
            gradingType: 'points',
            importantDates: false,
            onlyVisibleToOverrides: false,
            visibleToEveryone: true,
            dueAt: availableUntil,
            unlockAt: availableFrom,
            lockAt: availableUntil,
            gradingStandard: null,
            peerReviews: {
              __typename: 'PeerReviews',
              anonymousReviews: false,
              automaticReviews: false,
              count: 0,
              dueAt: null,
              enabled: false,
              intraReviews: false,
            },
            assignmentGroup: {
              __typename: 'AssignmentGroup',
              _id: '3',
              id: 'QXNzaWdubWVudEdyb3VwLTM=',
              name: 'Assignments',
            },
            assignmentOverrides: {
              __typename: 'AssignmentOverrideConnection',
              nodes: [],
            },
            hasSubAssignments: false,
            checkpoints: [],
            hasSubmittedSubmissions: false,
          },
          availableFrom,
          availableUntil,
        }),
      })

      // Submit form without enabling checkpoints
      getByText('Save').click()

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalled()
        const submissionData = mockOnSubmit.mock.calls[0][0]
        expect(submissionData.delayedPostAt).toBe(availableFrom)
        expect(submissionData.lockAt).toBe(availableUntil)
      })
    })
  })
})

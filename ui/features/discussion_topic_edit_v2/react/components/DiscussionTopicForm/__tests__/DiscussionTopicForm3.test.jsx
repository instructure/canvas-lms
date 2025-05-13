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

  describe('Revealing/hiding options', () => {
    it('shows AnonymousResponseSelector when Anonymity selector is partial', async () => {
      window.ENV.current_user.display_name = 'Student Name'
      const document = setup({
        currentDiscussionTopic: DiscussionTopic.mock({anonymousState: 'partial_anonymity'}),
        isStudent: true,
      })

      expect(document.queryByText('Replying as')).toBeTruthy()
    })

    it('does not show AnonymousResponseSelector when Anonymity selector is full', async () => {
      window.ENV.current_user.display_name = 'Student Name'
      const document = setup({
        currentDiscussionTopic: DiscussionTopic.mock({anonymousState: 'full_anonymity'}),
        isStudent: true,
      })

      expect(document.queryByText('Replying as')).toBeFalsy()
    })

    it('disables group and graded discussion options when Fully/Partially Anonymous', () => {
      const document = setup({
        currentDiscussionTopic: DiscussionTopic.mock({anonymousState: 'full_anonymity'}),
      })

      expect(document.queryByTestId('graded-checkbox')).toBeDisabled()
      expect(document.queryByTestId('group-discussion-checkbox')).toBeDisabled()
    })

    it('hides student ToDo, and ungraded options when Graded', () => {
      ENV = {
        FEATURES: {},
        STUDENT_PLANNER_ENABLED: true,
        DISCUSSION_TOPIC: {
          PERMISSIONS: {
            CAN_MANAGE_CONTENT: true,
            CAN_CREATE_ASSIGNMENT: true,
          },
        },
      }
      Object.assign(window.ENV, ENV)

      const {queryByTestId, getByLabelText, queryByLabelText} = setup()
      expect(queryByLabelText('Add to student to-do')).toBeInTheDocument()
      queryByLabelText('Add to student to-do').click()
      expect(queryByTestId('todo-date-section')).toBeInTheDocument()
      expect(queryByTestId('discussion-assign-to-section')).toBeInTheDocument()
      getByLabelText('Graded').click()
      expect(queryByLabelText('Add to student to-do')).not.toBeInTheDocument()
      expect(queryByTestId('todo-date-section')).not.toBeInTheDocument()
      expect(queryByTestId('assignment-assign-to-section')).toBeInTheDocument()
    })

    it('does not display AttachButton when CAN_ATTACH is false', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_ATTACH = false
      const document = setup()

      expect(document.queryByText('Attach')).toBeFalsy()
    })

    it('shows AnonymousOptions when conditions are met', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true

      const document = setup({isGroupContext: false})
      expect(document.queryAllByText('Anonymous Discussion')).toBeTruthy()
    })

    it('shows AnonymousOptions when students are explicitly allowed are met', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = false
      window.ENV.allow_student_anonymous_discussion_topics = true

      const document = setup({isGroupContext: false})
      expect(document.queryAllByText('Anonymous Discussion')).toBeTruthy()
    })

    it('does not Show AnonymousOptions when in group context', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = false

      const document = setup({isGroupContext: false})
      expect(document.queryByText('Anonymous Discussion')).toBeFalsy()
    })

    it('does not show usageRights when not enabled', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_ATTACH = true
      window.ENV.USAGE_RIGHTS_REQUIRED = false
      window.ENV.PERMISSIONS.manage_files = true

      const document = setup()
      expect(document.queryByText('Set usage rights')).toBeFalsy()
    })

    it('shows usageRights when enabled', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_ATTACH = true
      window.ENV.USAGE_RIGHTS_REQUIRED = true
      window.ENV.PERMISSIONS.manage_files = true

      const document = setup()
      expect(document.queryByText('Set usage rights')).toBeTruthy()
    })

    it('does not show liking options when in K5_homeRoom', () => {
      window.ENV.K5_HOMEROOM_COURSE = true

      const document = setup()
      expect(document.queryByText('Allow liking')).toBeFalsy()
    })

    it('shows liking options when not in K5_homeRoom', () => {
      window.ENV.K5_HOMEROOM_COURSE = false

      const document = setup()
      expect(document.queryByText('Allow liking')).toBeTruthy()
    })

    it('shows save and publish when not published', () => {
      const document = setup({
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })

      expect(document.queryByTestId('save-and-publish-button')).toBeTruthy()
    })

    it('does not show save and publish when published', () => {
      const document = setup({
        currentDiscussionTopic: DiscussionTopic.mock({published: true}),
      })

      expect(document.queryByTestId('save-and-publish-button')).toBeFalsy()
    })

    it('displays a warning when a user can not edit group category', () => {
      const document = setup({
        groupCategories: [{_id: '1', name: 'Mutant Power Training Group 1'}],
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({
          groupSet: GroupSet.mock(),
          canGroup: false,
          entryCounts: {repliesCount: 1},
        }),
      })

      expect(document.queryByTestId('group-category-not-editable')).toBeTruthy()
    })

    it('does not display a warning when a user can edit group category', () => {
      const document = setup({
        groupCategories: [{_id: '1', name: 'Mutant Power Training Group 1'}],
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({groupSet: GroupSet.mock(), canGroup: true}),
      })

      expect(document.queryByTestId('group-category-not-editable')).toBeFalsy()
    })

    it('displays the checkpoints checkbox when the Graded option is selected and discussion checkpoints flag is on', () => {
      const {queryByTestId, getByLabelText} = setup()

      expect(queryByTestId('checkpoints-checkbox')).not.toBeInTheDocument()

      getByLabelText('Graded').click()

      expect(queryByTestId('checkpoints-checkbox')).toBeInTheDocument()
    })

    it('renders the cancel button', () => {
      const {queryByTestId} = setup()
      expect(queryByTestId('announcement-cancel-button')).toBeInTheDocument()
    })

    it('does not display the checkpoints checkbox when the Graded option is not selected and discussion checkpoints flag is on', () => {
      const {queryByTestId} = setup()

      expect(queryByTestId('checkpoints-checkbox')).not.toBeInTheDocument()
    })

    it('does not display the checkpoints checkbox when the discussion checkpoints flag is off', () => {
      window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = false

      const {queryByTestId, getByLabelText} = setup()

      getByLabelText('Graded').click()

      expect(queryByTestId('checkpoints-checkbox')).not.toBeInTheDocument()
    })

    it('displays the checkpoints checkbox when RESTRICT_QUANTITATIVE_DATA is false', () => {
      const {queryByTestId, getByLabelText} = setup()

      getByLabelText('Graded').click()

      expect(queryByTestId('checkpoints-checkbox')).toBeInTheDocument()
    })

    it('does not display the checkpoints checkbox when RESTRICT_QUANTITATIVE_DATA is true', () => {
      window.ENV.RESTRICT_QUANTITATIVE_DATA = true

      const {queryByTestId, getByLabelText} = setup()

      getByLabelText('Graded').click()

      expect(queryByTestId('checkpoints-checkbox')).not.toBeInTheDocument()
    })

    it('disable checkpoints if there are student submissions', () => {
      const {queryByTestId} = setup({
        currentDiscussionTopic: DiscussionTopic.mock({
          assignment: Assignment.mock({
            hasSubmittedSubmissions: true,
          }),
        }),
      })

      expect(queryByTestId('checkpoints-checkbox')).toBeDisabled()
    })

    it('displays disabled "Allow Participants to Comment" when the setting is turned off', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.ANNOUNCEMENTS_COMMENTS_DISABLED = true

      const {queryByLabelText} = setup()
      const component = queryByLabelText('Allow Participants to Comment')

      expect(component).toBeInTheDocument()
      expect(component).toBeDisabled()
    })

    it('displays "Allow Participants to Comment" when the setting is turned on', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.ANNOUNCEMENTS_COMMENTS_DISABLED = false

      const {queryByText} = setup()

      expect(queryByText('Allow Participants to Comment')).toBeInTheDocument()
    })
  })

  describe('Disallow threaded replies', () => {
    it('disallow threaded replies checkbox is checked when discussion type is side comment and does not has threaded reply', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.has_threaded_replies = false
      const {getByTestId} = setup({currentDiscussionTopic: {discussionType: 'side_comment'}})

      const checkbox = getByTestId('disallow_threaded_replies')
      expect(checkbox).toHaveAttribute('data-action-state', 'allowThreads')
      expect(checkbox.checked).toBe(true)
    })

    it('disallow threaded replies checkbox is disabled when discussion type is side comment and has threaded replies', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.has_threaded_replies = true
      const {getByTestId} = setup({currentDiscussionTopic: {discussionType: 'side_comment'}})

      const checkbox = getByTestId('disallow_threaded_replies')
      expect(checkbox.disabled).toBe(true)
      expect(checkbox.checked).toBe(false)
    })

    it('disallow threaded replies checkbox is not present in announcements if "Allow participants to comment" is disabled', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.has_threaded_replies = false
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.ANNOUNCEMENTS_COMMENTS_DISABLED = true

      const {queryByTestId} = setup()

      expect(queryByTestId('disallow_threaded_replies')).not.toBeInTheDocument()
    })

    it('disallow threaded replies checkbox is enabled in dicussions if "Allow participants to comment" is disabled', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.has_threaded_replies = false
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
      window.ENV.ANNOUNCEMENTS_COMMENTS_DISABLED = true

      const {getByTestId} = setup({currentDiscussionTopic: {discussionType: 'threaded'}})

      const checkbox = getByTestId('disallow_threaded_replies')
      expect(checkbox).toHaveAttribute('data-action-state', 'disallowThreads')
      expect(checkbox.disabled).toBe(false)
      expect(checkbox.checked).toBe(false)
    })
  })
})

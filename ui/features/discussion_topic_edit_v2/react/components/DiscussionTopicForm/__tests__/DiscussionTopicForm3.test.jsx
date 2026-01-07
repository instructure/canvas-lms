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

import {render} from '@testing-library/react'
import React from 'react'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {GroupSet} from '../../../../graphql/GroupSet'
import DiscussionTopicForm from '../DiscussionTopicForm'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm - UI Options', () => {
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
    fakeENV.setup({
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
      context_type: 'Course',
      context_id: '1',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('Graded options', () => {
    it('hides student ToDo, and ungraded options when Graded', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.id = 1

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
  })

  describe('Attachment options', () => {
    it('does not display AttachButton when CAN_ATTACH is false', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_ATTACH = false
      const document = setup()

      expect(document.queryByText('Attach')).toBeFalsy()
    })
  })

  describe('Usage rights', () => {
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
  })

  describe('Liking options', () => {
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
  })

  describe('Publish options', () => {
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
  })

  describe('Group category', () => {
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
  })

  describe('Cancel button', () => {
    it('renders the cancel button', () => {
      const {queryByTestId} = setup()
      expect(queryByTestId('announcement-cancel-button')).toBeInTheDocument()
    })
  })
})

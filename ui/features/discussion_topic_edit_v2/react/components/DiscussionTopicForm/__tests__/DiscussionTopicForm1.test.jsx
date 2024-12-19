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

  it('renders', () => {
    const document = setup()
    expect(document.getByText('Topic Title')).toBeInTheDocument()
    expect(document.queryByText('Attach')).toBeTruthy()

    expect(document.queryByTestId('graded-checkbox')).toBeTruthy()
    expect(document.queryByTestId('group-discussion-checkbox')).toBeTruthy()
  })

  it('renders expected default teacher discussion options', () => {
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true

    const document = setup()
    // Default teacher options in order top to bottom
    expect(document.getByText('Topic Title')).toBeInTheDocument()
    expect(document.queryByText('Attach')).toBeTruthy()
    expect(document.queryByTestId('discussion-assign-to-section')).toBeTruthy()
    expect(document.queryAllByText('Anonymous Discussion')).toBeTruthy()
    expect(document.queryByLabelText('Disallow threaded replies')).toBeInTheDocument()
    expect(document.queryByTestId('require-initial-post-checkbox')).toBeTruthy()
    expect(document.queryByLabelText('Enable podcast feed')).toBeInTheDocument()
    expect(document.queryByTestId('graded-checkbox')).toBeTruthy()
    expect(document.queryByLabelText('Allow liking')).toBeInTheDocument()
    expect(document.queryByLabelText('Add to student to-do')).toBeInTheDocument()
    expect(document.queryByTestId('group-discussion-checkbox')).toBeTruthy()
    expect(document.queryAllByText('Available from')).toBeTruthy()
    expect(document.queryAllByText('Until')).toBeTruthy()

    // Hides announcement options
    expect(document.queryByLabelText('Allow Participants to Comment')).not.toBeInTheDocument()
  })

  it('renders expected default teacher announcement options', () => {
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
    window.ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true

    const document = setup()
    // Default teacher options in order top to bottom
    expect(document.getByText('Topic Title')).toBeInTheDocument()
    expect(document.queryByText('Attach')).toBeTruthy()
    expect(document.queryByTestId('section-select')).toBeTruthy()
    expect(document.queryByLabelText('Allow Participants to Comment')).toBeInTheDocument()
    expect(document.queryByLabelText('Enable podcast feed')).toBeInTheDocument()
    expect(document.queryByLabelText('Allow liking')).toBeInTheDocument()
    expect(document.queryByTestId('non-graded-date-options')).toBeTruthy()
    expect(document.queryAllByText('Available from')).toBeTruthy()
    expect(document.queryAllByText('Until')).toBeTruthy()

    // Hides discussion only options
    expect(document.queryByLabelText('Add to student to-do')).not.toBeInTheDocument()
    expect(document.queryByText('Anonymous Discussion')).not.toBeTruthy()
    expect(document.queryByTestId('graded-checkbox')).not.toBeTruthy()
    expect(document.queryByTestId('group-discussion-checkbox')).not.toBeTruthy()

    // hides mastery paths
    expect(document.queryByText('Mastery Paths')).toBeFalsy()
  })

  it('renders comment related fields when participants commenting is enabled in an announcement', () => {
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.has_threaded_replies = false
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
    window.ENV.ANNOUNCEMENTS_COMMENTS_DISABLED = false

    const {queryByTestId, queryByLabelText} = setup()

    const allowCommentsCheckbox = queryByLabelText('Allow Participants to Comment')
    allowCommentsCheckbox.click()
    expect(allowCommentsCheckbox).toBeChecked()
    expect(queryByLabelText('Disallow threaded replies')).toBeInTheDocument()
    expect(queryByTestId('require-initial-post-checkbox')).toBeInTheDocument()
  })

  it('renders reset buttons for availability dates when creating/editing an announcement', () => {
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true

    const document = setup()

    expect(document.queryAllByTestId('reset-available-from-button')).toHaveLength(1)
    expect(document.queryAllByTestId('reset-available-until-button')).toHaveLength(1)
  })

  describe('assignment edit placement', () => {
    it('renders if the discussion is not an announcement', () => {
      const {queryByTestId} = setup()
      expect(queryByTestId('assignment-external-tools')).toBeInTheDocument()
    })

    it('renders if it is an announcement and the assignment edit placement not on announcements FF is off', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        is_announcement: true,
      }
      const {queryByTestId} = setup()
      expect(queryByTestId('assignment-external-tools')).toBeInTheDocument()
    })

    it('does not render if it is an announcement and the assignment edit placement not on announcements FF is on', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        is_announcement: true,
      }
      window.ENV.ASSIGNMENT_EDIT_PLACEMENT_NOT_ON_ANNOUNCEMENTS = true
      const {queryByTestId} = setup()
      expect(queryByTestId('assignment-external-tools')).not.toBeInTheDocument()
    })

    it('does not render if the context is not a course', () => {
      ENV.context_is_not_group = false
      const {queryByTestId} = setup()
      expect(queryByTestId('assignment-external-tools')).not.toBeInTheDocument()
    })
  })

  describe('publish indicator', () => {
    it('does not show the publish indicator when editing an announcement', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        id: 88,
        is_announcement: true,
        course_published: false,
      }

      const {queryByText} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })

      // Verifies that the publish indicator is not in the document
      expect(queryByText('Published')).not.toBeInTheDocument()
      expect(queryByText('Not Published')).not.toBeInTheDocument()
    })

    it('displays the publish indicator with the text `Not Published` when not editing', () => {
      const {queryByText} = setup({isEditing: false})

      // Verifies that the publish indicator with the text Not Published is in the document
      expect(queryByText('Not Published')).toBeInTheDocument()
    })

    it('displays publish indicator correctly', () => {
      const {getByText} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: true}),
      })

      // Verifies that the publish indicator displays "Published"
      expect(getByText('Published')).toBeInTheDocument()
    })

    it('displays unpublished indicator correctly', () => {
      const {getByText} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })

      // Verifies that the publish indicator displays "Not Published"
      expect(getByText('Not Published')).toBeInTheDocument()
    })
  })

  describe('view settings', () => {
    beforeEach(() => {
      window.ENV.DISCUSSION_DEFAULT_EXPAND_ENABLED = true
      window.ENV.DISCUSSION_DEFAULT_SORT_ENABLED = true
    })

    it('renders view settings, if the discussion is not announcement', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
      const {queryByTestId} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })
      expect(queryByTestId('discussion-view-settings')).toBeInTheDocument()
    })

    it('does not render view settings, if the discussion is announcement', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      const {queryByTestId} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })
      expect(queryByTestId('discussion-view-settings')).not.toBeInTheDocument()
    })

    it('does not render view settings, if no features are enabled', () => {
      window.ENV.DISCUSSION_DEFAULT_EXPAND_ENABLED = false
      window.ENV.DISCUSSION_DEFAULT_SORT_ENABLED = false
      const {queryByTestId} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })
      expect(queryByTestId('discussion-view-settings')).not.toBeInTheDocument()
    })
  })
})

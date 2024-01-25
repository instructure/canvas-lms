// @vitest-environment jsdom
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
import userEvent from '@testing-library/user-event'
import React from 'react'
import DiscussionTopicForm from '../DiscussionTopicForm'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'

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
      />
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
    expect(document.queryByTestId('section-select')).toBeTruthy()
    expect(document.queryAllByText('Anonymous Discussion')).toBeTruthy()
    expect(document.queryByTestId('require-initial-post-checkbox')).toBeTruthy()
    expect(document.queryByLabelText('Enable podcast feed')).toBeInTheDocument()
    expect(document.queryByTestId('graded-checkbox')).toBeTruthy()
    expect(document.queryByLabelText('Allow liking')).toBeInTheDocument()
    expect(document.queryByLabelText('Add to student to-do')).toBeInTheDocument()
    expect(document.queryByTestId('group-discussion-checkbox')).toBeTruthy()
    expect(document.queryAllByText('Available from')).toBeTruthy()
    expect(document.queryAllByText('Until')).toBeTruthy()

    // Hides announcement options
    expect(document.queryByLabelText('Delay Posting')).not.toBeInTheDocument()
    expect(document.queryByLabelText('Allow Participants to Comment')).not.toBeInTheDocument()
  })

  it('renders expected default teacher announcement options', () => {
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true

    const document = setup()
    // Default teacher options in order top to bottom
    expect(document.getByText('Topic Title')).toBeInTheDocument()
    expect(document.queryByText('Attach')).toBeTruthy()
    expect(document.queryByTestId('section-select')).toBeTruthy()
    expect(document.queryByLabelText('Delay Posting')).toBeInTheDocument()
    expect(document.queryByLabelText('Allow Participants to Comment')).toBeInTheDocument()
    expect(document.queryByTestId('require-initial-post-checkbox')).toBeTruthy()
    expect(document.queryByLabelText('Enable podcast feed')).toBeInTheDocument()
    expect(document.queryByLabelText('Allow liking')).toBeInTheDocument()

    // Hides discussion only options
    expect(document.queryByLabelText('Add to student to-do')).not.toBeInTheDocument()
    expect(document.queryByText('Anonymous Discussion')).not.toBeTruthy()
    expect(document.queryByTestId('graded-checkbox')).not.toBeTruthy()
    expect(document.queryByTestId('group-discussion-checkbox')).not.toBeTruthy()
    expect(document.queryByText('Available from')).not.toBeTruthy()
    expect(document.queryByText('Until')).not.toBeTruthy()
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

  describe('Announcement Alerts', () => {
    it('shows an alert when creating an announcement in an unpublished course', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        is_announcement: true,
        course_published: false,
      }

      const document = setup()
      expect(
        document.getByText(
          'Notifications will not be sent retroactively for announcements created before publishing your course or before the course start date. You may consider using the Delay Posting option and set to publish on a future date.'
        )
      ).toBeInTheDocument()
    })

    it('shows an alert when editing an announcement in an published course', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        id: 5000,
        is_announcement: true,
        course_published: true,
      }

      const document = setup()
      expect(
        document.getByText(
          'Users do not receive updated notifications when editing an announcement. If you wish to have users notified of this update via their notification settings, you will need to create a new announcement.'
        )
      ).toBeInTheDocument()
    })

    it('shows the unpublished alert when editing an announcement in an unpublished course', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        id: 88,
        is_announcement: true,
        course_published: false,
      }

      const document = setup()
      expect(
        document.getByText(
          'Notifications will not be sent retroactively for announcements created before publishing your course or before the course start date. You may consider using the Delay Posting option and set to publish on a future date.'
        )
      ).toBeInTheDocument()
    })
  })

  describe('Title entry', () => {
    it('shows empty title reminder', () => {
      const {getByText, getByPlaceholderText} = setup()
      getByPlaceholderText('Topic Title').focus()
      getByText('Save').click()
      expect(getByText('Title must not be empty.')).toBeInTheDocument()
    })

    it('submits only with non-empty title', () => {
      const onSubmit = jest.fn()
      const {getByText, getByPlaceholderText} = setup({onSubmit})
      const saveButton = getByText('Save')
      saveButton.click()
      expect(onSubmit).not.toHaveBeenCalled()
      fireEvent.input(getByPlaceholderText('Topic Title'), {target: {value: 'a title'}})
      saveButton.click()
      expect(onSubmit).toHaveBeenCalled()
    })

    it('shows too-long title reminder', async () => {
      const {getByText, getByLabelText} = setup()
      const titleInput = getByLabelText(/Topic Title/)
      fireEvent.input(titleInput, {target: {value: 'A'.repeat(260)}})
      userEvent.type(titleInput, 'A')
      await waitFor(() =>
        expect(getByText('Title must be less than 255 characters.')).toBeInTheDocument()
      )
    })
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

    it('hides group and graded discussion options when Fully/Partially Anonymous', () => {
      const document = setup({
        currentDiscussionTopic: DiscussionTopic.mock({anonymousState: 'full_anonymity'}),
      })

      expect(document.queryByTestId('graded-checkbox')).toBeFalsy()
      expect(document.queryByTestId('group-discussion-checkbox')).toBeFalsy()
    })

    it('hides post to section, student ToDo, and ungraded options when Graded', () => {
      ENV = {
        STUDENT_PLANNER_ENABLED: true,
        DISCUSSION_TOPIC: {
          PERMISSIONS: {
            CAN_MANAGE_CONTENT: true,
            CAN_CREATE_ASSIGNMENT: true,
          },
        },
      }
      Object.assign(window.ENV, ENV)

      const {queryByText, queryByTestId, getByLabelText, queryByLabelText} = setup()
      expect(queryByLabelText('Add to student to-do')).toBeInTheDocument()
      queryByLabelText('Add to student to-do').click()
      expect(queryByTestId('todo-date-section')).toBeInTheDocument()
      expect(queryByText('All Sections')).toBeInTheDocument()
      expect(queryByTestId('assignment-settings-section')).not.toBeInTheDocument()
      getByLabelText('Graded').click()
      expect(queryByLabelText('Add to student to-do')).not.toBeInTheDocument()
      expect(queryByTestId('todo-date-section')).not.toBeInTheDocument()
      expect(queryByLabelText('Post to')).not.toBeInTheDocument()
      expect(queryByTestId('assignment-settings-section')).toBeInTheDocument()
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
      window.ENV.FEATURES.usage_rights_discussion_topics = true
      window.ENV.USAGE_RIGHTS_REQUIRED = false
      window.ENV.PERMISSIONS.manage_files = true

      const document = setup()
      expect(document.queryByText('Set usage rights')).toBeFalsy()
    })

    it('shows usageRights when enabled', () => {
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_ATTACH = true
      window.ENV.FEATURES.usage_rights_discussion_topics = true
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
  })
})

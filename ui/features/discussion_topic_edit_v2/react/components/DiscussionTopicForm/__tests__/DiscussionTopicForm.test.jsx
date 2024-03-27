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
import {GroupSet} from '../../../../graphql/GroupSet'

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
      DISCUSSION_CHECKPOINTS_ENABLED: true,
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
      await userEvent.type(titleInput, 'A')
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

    it('displays a warning when a user can not edit group category', () => {
      const document = setup({
        groupCategories: [{_id: '1', name: 'Mutant Power Training Group 1'}],
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({groupSet: GroupSet.mock(), canGroup: false}),
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
    describe('Checkpoints Settings', () => {
      it('increments and decrements the checkpoints settings points possible reply to topic fields', () => {
        const {getByTestId, getByLabelText} = setup()

        getByLabelText('Graded').click()

        const checkbox = getByTestId('checkpoints-checkbox')
        checkbox.click()

        const numberInputReplyToTopic = getByTestId('points-possible-input-reply-to-topic')
        expect(numberInputReplyToTopic.value).toBe('0')

        fireEvent.click(numberInputReplyToTopic)

        fireEvent.keyDown(numberInputReplyToTopic, {keyCode: 38})
        expect(numberInputReplyToTopic.value).toBe('1')

        fireEvent.keyDown(numberInputReplyToTopic, {keyCode: 40})
        expect(numberInputReplyToTopic.value).toBe('0')
      })
      it('increments and decrements the checkpoints settings points possible reply to entry fields', () => {
        const {getByTestId, getByLabelText} = setup()

        getByLabelText('Graded').click()

        const checkbox = getByTestId('checkpoints-checkbox')
        checkbox.click()

        const numberInputReplyToEntry = getByTestId('points-possible-input-reply-to-entry')
        expect(numberInputReplyToEntry.value).toBe('0')

        fireEvent.click(numberInputReplyToEntry)

        fireEvent.keyDown(numberInputReplyToEntry, {keyCode: 38})
        expect(numberInputReplyToEntry.value).toBe('1')

        fireEvent.keyDown(numberInputReplyToEntry, {keyCode: 40})
        expect(numberInputReplyToEntry.value).toBe('0')
      })
      it('increments and decrements the checkpoints settings additional replies required entry field', () => {
        const {getByTestId, getByLabelText} = setup()

        getByLabelText('Graded').click()

        const checkbox = getByTestId('checkpoints-checkbox')
        checkbox.click()

        const numberInputReplyToEntryRequiredCount = getByTestId('reply-to-entry-required-count')
        expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

        fireEvent.click(numberInputReplyToEntryRequiredCount)

        fireEvent.keyDown(numberInputReplyToEntryRequiredCount, {keyCode: 38})
        expect(numberInputReplyToEntryRequiredCount.value).toBe('2')

        fireEvent.keyDown(numberInputReplyToEntryRequiredCount, {keyCode: 40})
        expect(numberInputReplyToEntryRequiredCount.value).toBe('1')
      })
      it('does not submit when the required replies count is greater than maximum allowed count', () => {
        const onSubmit = jest.fn()
        const {container, getByText, getByLabelText, getByTestId, getByPlaceholderText} = setup({onSubmit})

        fireEvent.input(getByPlaceholderText('Topic Title'), {target: {value: 'a title'}})

        getByLabelText('Graded').click()

        const checkbox = getByTestId('checkpoints-checkbox')
        checkbox.click()

        const numberInputReplyToEntryRequiredCount = getByTestId('reply-to-entry-required-count')
        fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: '11'}})

        expect(container).toHaveTextContent("This number must be between 1 and 10")

        const saveButton = getByText('Save')
        saveButton.click()

        expect(onSubmit).not.toHaveBeenCalled()
      })
      it('submits when the required replies count is between the minimum and maximum allowed count, inclusive', () => {
        const onSubmit = jest.fn()
        const {getByText, getByLabelText, getByTestId, getByPlaceholderText} = setup({onSubmit})

        fireEvent.input(getByPlaceholderText('Topic Title'), {target: {value: 'a title'}})

        getByLabelText('Graded').click()

        const checkbox = getByTestId('checkpoints-checkbox')
        checkbox.click()

        const numberInputReplyToEntryRequiredCount = getByTestId('reply-to-entry-required-count')
        fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: '10'}})

        const saveButton = getByText('Save')
        saveButton.click()

        expect(onSubmit).toHaveBeenCalled()
      })
    })
  })
})
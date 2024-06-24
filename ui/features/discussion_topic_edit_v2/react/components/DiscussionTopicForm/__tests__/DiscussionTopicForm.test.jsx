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
import DiscussionTopicForm, {isGuidDataValid, getAbGuidArray} from '../DiscussionTopicForm'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {Assignment} from '../../../../graphql/Assignment'
import {GroupSet} from '../../../../graphql/GroupSet'
import {REPLY_TO_TOPIC, REPLY_TO_ENTRY} from '../../../util/constants'

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
    expect(document.queryByLabelText('Allow Participants to Comment')).not.toBeInTheDocument()
  })

  it('renders reset buttons for availability dates when creating/editing a discussion topic', () => {
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true

    const document = setup()

    expect(document.queryAllByTestId('reset-available-from-button').length).toBe(1)
    expect(document.queryAllByTestId('reset-available-until-button').length).toBe(1)
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
    expect(document.queryByTestId('require-initial-post-checkbox')).toBeTruthy()
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

  it('renders reset buttons for availability dates when creating/editing an announcement', () => {
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true

    const document = setup()

    expect(document.queryAllByTestId('reset-available-from-button').length).toBe(1)
    expect(document.queryAllByTestId('reset-available-until-button').length).toBe(1)
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

        it('increments and decrements the checkpoints settings points possible reply to topic fields', () => {
          setupCheckpoints(setup())

          const numberInputReplyToTopic = getByTestId('points-possible-input-reply-to-topic')
          expect(numberInputReplyToTopic.value).toBe('0')

          fireEvent.click(numberInputReplyToTopic)

          fireEvent.keyDown(numberInputReplyToTopic, {keyCode: 38})
          expect(numberInputReplyToTopic.value).toBe('1')

          fireEvent.keyDown(numberInputReplyToTopic, {keyCode: 40})
          expect(numberInputReplyToTopic.value).toBe('0')
        })
        it('increments and decrements the checkpoints settings points possible reply to entry fields', () => {
          setupCheckpoints(setup())

          const numberInputReplyToEntry = getByTestId('points-possible-input-reply-to-entry')
          expect(numberInputReplyToEntry.value).toBe('0')

          fireEvent.click(numberInputReplyToEntry)

          fireEvent.keyDown(numberInputReplyToEntry, {keyCode: 38})
          expect(numberInputReplyToEntry.value).toBe('1')

          fireEvent.keyDown(numberInputReplyToEntry, {keyCode: 40})
          expect(numberInputReplyToEntry.value).toBe('0')
        })
        describe('Additional Replies Required', () => {
          it('increments and decrements the checkpoints settings additional replies required entry field', () => {
            setupCheckpoints(setup())

            const numberInputReplyToEntryRequiredCount = getByTestId(
              'reply-to-entry-required-count'
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
              'reply-to-entry-required-count'
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
              'reply-to-entry-required-count'
            )
            expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

            fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: '6'}})
            expect(numberInputReplyToEntryRequiredCount.value).toBe('6')
          })
          it('does not allow input to be changed if the required count falls outside the allowed range', () => {
            setupCheckpoints(setup())

            const numberInputReplyToEntryRequiredCount = getByTestId(
              'reply-to-entry-required-count'
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
              'reply-to-entry-required-count'
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

  describe('Ungraded', () => {
    describe('selective_release_ui_api flag is ON', () => {
      beforeAll(() => {
        window.ENV.FEATURES.selective_release_ui_api = true
      })

      it('renders expected default teacher discussion options', () => {
        window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_CREATE_ASSIGNMENT = true
        window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_UPDATE_ASSIGNMENT = true
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
        expect(document.queryAllByText('Manage Assign To')).toBeTruthy()

        // Hides announcement options
        expect(document.queryByLabelText('Delay Posting')).not.toBeInTheDocument()
        expect(document.queryByLabelText('Allow Participants to Comment')).not.toBeInTheDocument()
      })

      it('renders expected default student discussion options', () => {
        window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_CREATE_ASSIGNMENT = false
        window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_UPDATE_ASSIGNMENT = false
        window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = false
        window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = false

        const document = setup()
        // Default teacher options in order top to bottom
        expect(document.getByText('Topic Title')).toBeInTheDocument()
        expect(document.queryByText('Attach')).toBeTruthy()
        expect(document.queryByTestId('section-select')).toBeTruthy()
        expect(document.queryAllByText('Anonymous Discussion')).toBeTruthy()
        expect(document.queryByTestId('require-initial-post-checkbox')).toBeTruthy()
        expect(document.queryByLabelText('Allow liking')).toBeInTheDocument()
        expect(document.queryByTestId('group-discussion-checkbox')).toBeTruthy()
        expect(document.queryAllByText('Available from')).toBeTruthy()
        expect(document.queryAllByText('Until')).toBeTruthy()

        // Hides announcement options
        expect(document.queryByLabelText('Delay Posting')).not.toBeInTheDocument()
        expect(document.queryByLabelText('Allow Participants to Comment')).not.toBeInTheDocument()
      })
    })
  })
})

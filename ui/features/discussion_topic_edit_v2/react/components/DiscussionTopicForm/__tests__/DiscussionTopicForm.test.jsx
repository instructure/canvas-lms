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

const setup = ({
  isEditing = false,
  currentDiscussionTopic = {},
  assignmentGroups = [],
  isStudent = false,
  sections = [],
  groupCategories = [],
  onSubmit = () => {},
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
      isGroupContext={false}
    />
  )
}

describe('DiscussionTopicForm', () => {
  afterEach(() => {
    window.ENV = {}
  })

  it('renders', () => {
    const document = setup()
    expect(document.getByText('Topic Title')).toBeInTheDocument()
  })

  describe('publish indicator', () => {
    it('does not show the publish indicator when editing an announcement', () => {
      window.ENV = {
        DISCUSSION_TOPIC: {
          ATTRIBUTES: {
            id: 88,
            is_announcement: true,
            course_published: false,
          },
        },
      }

      const {queryByText} = setup({
        isEditing: true,
        currentDiscussionTopic: DiscussionTopic.mock({published: false}),
      })

      // Verifies that the publish indicator is not in the document
      expect(queryByText('Published')).not.toBeInTheDocument()
      expect(queryByText('Not Published')).not.toBeInTheDocument()
    })

    it('does not show the publish indicator when not editing', () => {
      const {queryByText} = setup({isEditing: false})

      // Verifies that the publish indicator is not in the document
      expect(queryByText('Published')).not.toBeInTheDocument()
      expect(queryByText('Not Published')).not.toBeInTheDocument()
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
      window.ENV = {
        DISCUSSION_TOPIC: {
          ATTRIBUTES: {
            is_announcement: true,
            course_published: false,
          },
        },
      }

      const document = setup()
      expect(
        document.getByText(
          'Notifications will not be sent retroactively for announcements created before publishing your course or before the course start date. You may consider using the Delay Posting option and set to publish on a future date.'
        )
      ).toBeInTheDocument()
    })

    it('shows an alert when editing an announcement in an published course', () => {
      window.ENV = {
        DISCUSSION_TOPIC: {
          ATTRIBUTES: {
            id: 5000,
            is_announcement: true,
            course_published: true,
          },
        },
      }

      const document = setup()
      expect(
        document.getByText(
          'Users do not receive updated notifications when editing an announcement. If you wish to have users notified of this update via their notification settings, you will need to create a new announcement.'
        )
      ).toBeInTheDocument()
    })

    it('shows the unpublished alert when editing an announcement in an unpublished course', () => {
      window.ENV = {
        DISCUSSION_TOPIC: {
          ATTRIBUTES: {
            id: 88,
            is_announcement: true,
            course_published: false,
          },
        },
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
      const titleInput = getByLabelText('Topic Title')
      fireEvent.input(titleInput, {target: {value: 'A'.repeat(260)}})
      userEvent.type(titleInput, 'A')
      await waitFor(() =>
        expect(getByText('Title must be less than 255 characters.')).toBeInTheDocument()
      )
    })
  })

  describe('Revealing/hiding options', () => {
    // it('shows AnonymousResponseSelector when Anonymity selector is partial', async () => {
    //   const {getByRole, getByLabelText} = setup()
    //   const radioInputPartial = getByRole('radio', {
    //     name: 'Partial: students can choose to reveal their name and profile picture',
    //   })
    //   .click(radioInputPartial)
    //   expect(radioInputPartial).toBeChecked() // this will fail! TODO: investigate how to check InstUI RadioInput
    //   await waitFor(() => expect(getByLabelText('This is a Group Discussion')).not.toBeVisible())
    // })

    // it('hides group discussion when Fully/Partially Anonymous', () => {
    //   const {getByLabelText, queryByLabelText} = setup()
    //   expect(queryByLabelText('This is a Group Discussion')).toBeInTheDocument()
    //   getByLabelText(
    //     'Partial: students can choose to reveal their name and profile picture'
    //   ).click()
    //   expect(queryByLabelText('This is a Group Discussion')).not.toBeInTheDocument() // this will fail!
    // })

    it('hides post to section, student ToDo, and ungraded options when Graded', () => {
      window.ENV = {
        STUDENT_PLANNER_ENABLED: true,
        DISCUSSION_TOPIC: {
          PERMISSIONS: {
            CAN_MANAGE_CONTENT: true,
          },
        },
      }

      const {queryByText, queryByTestId, getByLabelText, queryByLabelText} = setup()
      expect(queryByLabelText('Add to student to-do')).toBeInTheDocument()
      expect(queryByText('All Sections')).toBeInTheDocument()
      expect(queryByTestId('assignment-settings-section')).not.toBeInTheDocument()
      getByLabelText('Graded').click()
      expect(queryByLabelText('Add to student to-do')).not.toBeInTheDocument()
      expect(queryByLabelText('Post to')).not.toBeInTheDocument()
      expect(queryByTestId('assignment-settings-section')).toBeInTheDocument()
    })
  })
})

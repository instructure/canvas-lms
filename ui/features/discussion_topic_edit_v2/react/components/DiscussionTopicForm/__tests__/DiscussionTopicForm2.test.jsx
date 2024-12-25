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

  describe('Announcement Alerts', () => {
    it('shows an alert when creating an announcement in an unpublished course', () => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
        is_announcement: true,
        course_published: false,
      }

      const document = setup()
      expect(
        document.getByText(
          'Notifications will not be sent retroactively for announcements created before publishing your course or before the course start date. You may consider using the Available from option and set to publish on a future date.',
        ),
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
          'Notifications will not be sent retroactively for announcements created before publishing your course or before the course start date. You may consider using the Available from option and set to publish on a future date.',
        ),
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
        expect(getByText('Title must be less than 255 characters.')).toBeInTheDocument(),
      )
    })
  })
})

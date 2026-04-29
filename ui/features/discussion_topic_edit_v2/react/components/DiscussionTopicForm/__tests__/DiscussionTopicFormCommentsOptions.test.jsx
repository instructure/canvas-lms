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
import DiscussionTopicForm from '../DiscussionTopicForm'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm - Comments Options', () => {
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

  it('displays "Allow Participants to Comment"', () => {
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
    window.ENV.ANNOUNCEMENTS_COMMENTS_DISABLED = false

    const {queryByText} = setup()

    expect(queryByText('Allow Participants to Comment')).toBeInTheDocument()
  })

  describe('when ANNOUNCEMENTS_COMMENTS_DISABLED is true', () => {
    beforeEach(() => {
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.ANNOUNCEMENTS_COMMENTS_DISABLED = true
    })

    it('displays disabled "Allow Participants to Comment"', () => {
      const {queryByLabelText} = setup()
      const component = queryByLabelText('Allow Participants to Comment')

      expect(component).toBeInTheDocument()
      expect(component).toBeDisabled()
    })

    describe('when GROUP_CONTEXT_TYPE is set to null', () => {
      it('renders tooltip for "Allow Participants to Comment" with the correct message', () => {
        window.ENV.GROUP_CONTEXT_TYPE = null

        const {queryByText} = setup()
        const component = queryByText('This option is locked in course settings')
        expect(component).toBeInTheDocument()
      })
    })

    describe('when GROUP_CONTEXT_TYPE is set to Course', () => {
      it('renders tooltip for "Allow Participants to Comment" with the correct message', () => {
        window.ENV.GROUP_CONTEXT_TYPE = 'Course'

        const {queryByText} = setup()
        const component = queryByText('This option is locked in course settings')
        expect(component).toBeInTheDocument()
      })
    })

    describe('when GROUP_CONTEXT_TYPE is set to Account', () => {
      it('renders tooltip for "Allow Participants to Comment" with the correct message', () => {
        window.ENV.GROUP_CONTEXT_TYPE = 'Account'

        const {queryByText} = setup()
        const component = queryByText('This option is locked in account settings')
        expect(component).toBeInTheDocument()
      })
    })
  })
})

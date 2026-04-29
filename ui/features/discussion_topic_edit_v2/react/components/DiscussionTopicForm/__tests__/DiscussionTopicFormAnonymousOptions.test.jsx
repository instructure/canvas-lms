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
import DiscussionTopicForm from '../DiscussionTopicForm'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm - Anonymous Options', () => {
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

    expect(document.queryByTestId('graded-checkbox').querySelector('input')).toBeDisabled()
    expect(
      document.queryByTestId('group-discussion-checkbox').querySelector('input'),
    ).toBeDisabled()
  })

  it('shows AnonymousOptions when conditions are met', () => {
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true

    const document = setup({isGroupContext: false})
    expect(document.queryAllByText('Anonymous Discussion')).toBeTruthy()
  })

  it('shows AnonymousOptions when students are explicitly allowed', () => {
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = false
    window.ENV.allow_student_anonymous_discussion_topics = true

    const document = setup({isGroupContext: false})
    expect(document.queryAllByText('Anonymous Discussion')).toBeTruthy()
  })

  it('does not show AnonymousOptions when in group context', () => {
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = false
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = false

    const document = setup({isGroupContext: false})
    expect(document.queryByText('Anonymous Discussion')).toBeFalsy()
  })
})

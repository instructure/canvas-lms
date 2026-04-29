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
import {Assignment} from '../../../../graphql/Assignment'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {GroupSet} from '../../../../graphql/GroupSet'
import DiscussionTopicForm from '../DiscussionTopicForm'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm - Checkpoints Display', () => {
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

  it('displays the checkpoints checkbox when the Graded option is selected and discussion checkpoints flag is on', () => {
    const {queryByTestId, getByLabelText} = setup()

    expect(queryByTestId('checkpoints-checkbox')).not.toBeInTheDocument()

    getByLabelText('Graded').click()

    expect(queryByTestId('checkpoints-checkbox')).toBeInTheDocument()
  })

  it('displays the suppress assignments checkbox when the Graded option is selected and suppress assignments setting is on', () => {
    window.ENV.SETTINGS.suppress_assignments = true

    const {queryByTestId, getByLabelText} = setup()

    expect(queryByTestId('suppressed-assignment-checkbox')).not.toBeInTheDocument()

    getByLabelText('Graded').click()

    expect(queryByTestId('suppressed-assignment-checkbox')).toBeInTheDocument()
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

  it('disables checkpoints if there are student submissions', () => {
    const {queryByTestId} = setup({
      isEditing: true,
      currentDiscussionTopic: DiscussionTopic.mock({
        assignment: Assignment.mock(),
        canGroup: false,
      }),
    })

    expect(queryByTestId('checkpoints-checkbox').querySelector('input')).toBeDisabled()
  })

  it('disables checkpoints for group discussions with child topic replies', () => {
    const {queryByTestId} = setup({
      isEditing: true,
      currentDiscussionTopic: DiscussionTopic.mock({
        assignment: Assignment.mock(),
        groupSet: GroupSet.mock(),
        canGroup: false,
      }),
    })

    expect(queryByTestId('checkpoints-checkbox').querySelector('input')).toBeDisabled()
  })
})

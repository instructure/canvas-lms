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

  describe('Todo Date', () => {
    it('clears todo date in submission when switching to graded', async () => {
      const mockOnSubmit = jest.fn()
      const todoDate = '2024-12-31T23:59:00Z'
      const {getByRole, getByLabelText} = setup({
        onSubmit: mockOnSubmit,
        currentDiscussionTopic: DiscussionTopic.mock({
          todoDate,
          addToTodo: true,
        }),
      })

      // Switch to graded
      getByLabelText('Graded').click()

      // Submit form
      getByRole('button', {name: 'Save'}).click()

      // Verify submission
      expect(mockOnSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          todoDate: null,
          assignment: expect.any(Object),
        }),
        false,
      )
    })

    it('preserves todo date in ungraded mode', async () => {
      const mockOnSubmit = jest.fn()
      const todoDate = '2024-12-31T23:59:00Z'
      const {getByRole} = setup({
        onSubmit: mockOnSubmit,
        currentDiscussionTopic: DiscussionTopic.mock({
          todoDate,
          addToTodo: true,
        }),
      })

      // Submit form
      getByRole('button', {name: 'Save'}).click()

      // Verify submission
      expect(mockOnSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          todoDate,
          assignment: null,
        }),
        false,
      )
    })
  })

  // returns 12:00 AM in jsdom 25
  it.skip('applies fancy midnight to assign reviews when needed', () => {
    const {getByTestId, getByLabelText, getByText} = setup()

    getByLabelText('Graded').click()
    getByLabelText('Automatically assign').click()

    const dueDate = getByTestId('reviews-due-date')
    const dueTime = getByTestId('reviews-due-time')

    expect(dueDate).toBeInTheDocument()
    expect(dueTime).toBeInTheDocument()

    fireEvent.change(dueDate, {target: {value: 'Nov 9, 2020'}})
    fireEvent.click(getByText('10 November 2020'))

    expect(dueTime).toHaveValue('11:59 PM')
  })

  it('does not apply fancy midnight to assign reviews when the user have other time set', () => {
    const {getByTestId, getByLabelText, getByText} = setup()

    getByLabelText('Graded').click()
    getByLabelText('Automatically assign').click()

    const dueDate = getByTestId('reviews-due-date')
    const dueTime = getByTestId('reviews-due-time')

    expect(dueDate).toBeInTheDocument()
    expect(dueTime).toBeInTheDocument()

    fireEvent.change(dueTime, {target: {value: '10:00 AM'}})
    fireEvent.click(getByText('10:00 AM'))

    fireEvent.change(dueDate, {target: {value: 'Nov 9, 2020'}})
    fireEvent.click(getByText('10 November 2020'))

    expect(dueTime).toHaveValue('10:00 AM')
  })
})

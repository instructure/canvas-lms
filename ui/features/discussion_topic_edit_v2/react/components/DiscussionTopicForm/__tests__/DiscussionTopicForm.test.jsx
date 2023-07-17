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

jest.mock('@canvas/rce/react/CanvasRce')

const setup = ({
  isEditing = false,
  currentDiscussionTopic = {},
  isStudent = false,
  sections = [],
  groupCategories = [],
  onSubmit = () => {},
} = {}) => {
  return render(
    <DiscussionTopicForm
      isEditing={isEditing}
      currentDiscussionTopic={currentDiscussionTopic}
      isStudent={isStudent}
      sections={sections}
      groupCategories={groupCategories}
      onSubmit={onSubmit}
    />
  )
}

describe('DiscussionTopicForm', () => {
  it('renders', () => {
    const document = setup()
    expect(document.getByText('Topic Title')).toBeInTheDocument()
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
      const {queryByText, getByLabelText, queryByLabelText} = setup()
      expect(queryByLabelText('Add to student to-do')).toBeInTheDocument()
      expect(queryByText('All Sections')).toBeInTheDocument()
      expect(queryByText('Graded options here')).not.toBeInTheDocument() // TODO: Update in Phase 2
      getByLabelText('Graded').click()
      expect(queryByLabelText('Add to student to-do')).not.toBeInTheDocument()
      expect(queryByLabelText('Post to')).not.toBeInTheDocument()
      expect(queryByText('Graded options here')).toBeInTheDocument() // TODO: Update in Phase 2
    })
  })
})

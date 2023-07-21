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

import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import DiscussionTopicForm from '../DiscussionTopicForm'

describe('DiscussionTopicForm', () => {
  test('renders', () => {
    const {getByText} = render(<DiscussionTopicForm />)
    expect(getByText('Topic Title')).toBeInTheDocument()
  })
  test('shows default title reminder', async () => {
    const {getByText, getByPlaceholderText} = render(<DiscussionTopicForm />)
    getByPlaceholderText('Topic Title').focus()
    getByText('Save').click()
    await waitFor(() => expect(getByText('Title must not be empty.')).toBeInTheDocument())
  })

  test('shows too-long title reminder', async () => {
    const {getByText, getByPlaceholderText} = render(<DiscussionTopicForm />)
    const input = getByPlaceholderText('Topic Title')
    await userEvent.type(input, 'A'.repeat(260), {delay: 1})
    await waitFor(() =>
      expect(getByText('Title must be less than 255 characters.')).toBeInTheDocument()
    )
  })
})

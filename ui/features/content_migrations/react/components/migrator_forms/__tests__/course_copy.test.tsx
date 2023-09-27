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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import CourseCopyImporter from '../course_copy'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'

it('Searches for matching courses on searchbox value change', async () => {
  window.ENV.current_user = {
    id: '0',
    anonymous_id: '',
    display_name: '',
    avatar_image_url: '',
    html_url: '',
    pronouns: '',
  }
  fetchMock.mock('/users/0/manageable_courses?term=math', [
    {
      id: '0',
      label: 'Mathmatics',
    },
  ])
  render(<CourseCopyImporter setSourceCourse={jest.fn()} />)
  expect(screen.getByText('Search for a course')).toBeInTheDocument()
  userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
  await waitFor(() => {
    expect(fetchMock.calls(`/users/0/manageable_courses?term=math`).length).toBe(1)
  })
  expect(screen.getByText('Mathmatics')).toBeInTheDocument()
})

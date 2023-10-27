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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import CommonMigratorControls from '../common_migrator_controls'

const onSubmit = jest.fn()
const onCancel = jest.fn()

describe('CommonMigratorControls', () => {
  beforeAll(() => {
    fetchMock.mock('/api/v1/courses/0/content_migrations/migrators', [
      {
        name: 'Mock Migrator',
        type: 'mock_migrator',
      },
    ])
  })

  afterEach(() => jest.clearAllMocks())

  it('calls onSubmit', async () => {
    render(<CommonMigratorControls onSubmit={onSubmit} onCancel={onCancel} />)
    userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
    expect(onSubmit).toHaveBeenCalledWith({
      date_shift_options: false,
      selective_import: false,
      settings: {import_quizzes_next: false},
    })
  })

  it('calls onCancel', async () => {
    render(<CommonMigratorControls onSubmit={onSubmit} onCancel={onCancel} />)
    userEvent.click(screen.getByRole('button', {name: 'Cancel'}))
    expect(onCancel).toHaveBeenCalled()
  })
})

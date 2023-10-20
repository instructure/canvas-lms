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
import ContentMigrationsForm from '../migrations_form'
import fetchMock from 'fetch-mock'

describe('ContentMigrationForm', () => {
  beforeAll(() => {
    fetchMock.mock('/api/v1/courses/0/content_migrations/migrators', [
      {
        name: 'Mock Migrator',
        type: 'mock_migrator',
      },
    ])
  })

  it('Waits for loading of migrator options', async () => {
    window.ENV.COURSE_ID = '0'
    render(<ContentMigrationsForm migrations={[]} setMigrations={jest.fn()} />)
    expect(screen.getByText('Loading options...')).toBeInTheDocument()
  })

  it('Populates select with migrator options', async () => {
    window.ENV.COURSE_ID = '0'
    render(<ContentMigrationsForm migrations={[]} setMigrations={jest.fn()} />)
    const selectOne = await screen.findByTitle('Select one')
    userEvent.click(selectOne)
    expect(screen.getByText('Mock Migrator')).toBeInTheDocument()
  })
})

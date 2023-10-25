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
import {render, waitFor, screen} from '@testing-library/react'
import ContentMigrationsTable from '../migrations_table'
import fetchMock from 'fetch-mock'

describe('ContentMigrationTable', () => {
  let setMigrationsMock: () => void

  beforeAll(() => {
    setMigrationsMock = jest.fn(() => {})
    fetchMock.mock('/api/v1/courses/0/content_migrations?per_page=25', ['api_return'])
  })

  it('Calls the API and renders the InstUI table', async () => {
    window.ENV.COURSE_ID = '0'
    render(<ContentMigrationsTable migrations={[]} setMigrations={setMigrationsMock} />)
    expect(screen.getByRole('table', {hidden: false})).toBeInTheDocument()
    expect(
      screen.getByRole('row', {
        name: 'Content Type Source Link Date Imported Status Progress Action',
        hidden: false,
      })
    ).toBeInTheDocument()
    expect(fetchMock.called('/api/v1/courses/0/content_migrations?per_page=25', 'GET')).toBe(true)
    await waitFor(() => {
      expect(setMigrationsMock).toHaveBeenCalledWith(['api_return'])
    })
  })
})

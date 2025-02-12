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
import fetchMock from 'fetch-mock'
import '@testing-library/jest-dom/extend-expect'
import {App} from '../app'
import doFetchApi from '@canvas/do-fetch-api-effect'

// Mock the doFetchApi function
jest.mock('@canvas/do-fetch-api-effect')

const mockMigrations = [
  {
    id: 1,
    migration_type: 'common_cartridge_importer',
    migration_type_title: 'Common Cartridge',
    type: 'common_cartridge_importer',
    migration_settings: {},
    progress_url: '/api/v1/progress/1',
    user_id: 1,
    workflow_state: 'completed',
    created_at: '2021-01-01T00:00:00Z',
    updated_at: '2021-01-01T00:00:00Z',
  },
  {
    id: 2,
    migration_type: 'zip_file_importer',
    type: 'zip_file_importer',
    migration_type_title: 'Zip File',
    migration_settings: {},
    progress_url: '/api/v1/progress/2',
    user_id: 1,
    workflow_state: 'completed',
    created_at: '2021-01-02T00:00:00Z',
    updated_at: '2021-01-02T00:00:00Z',
  },
]

describe('App', () => {
  beforeEach(() => {
    // @ts-expect-error
    doFetchApi.mockResolvedValue({ json: mockMigrations })
  })

  afterEach(() => {
    jest.clearAllMocks()
    fetchMock.restore()
  })

  it('renders loading spinner while loading', async () => {
    render(<App />)

    expect(screen.getByText('Loading')).toBeInTheDocument()
  })
  
  it('renders the content migrations table with data', async () => {
    render(<App />)

    await waitFor(() => {
      expect(screen.getByText(/Common Cartridge/)).toBeInTheDocument()
      expect(screen.getByText(/Zip File/)).toBeInTheDocument()
    })
  })

  it('renders the form', async () => {
    render(<App />)

    await waitFor(() => {
      expect(screen.getByText('Select Content Type')).toBeInTheDocument()
    })
  })

  it('fetches first page of migrations on mount', async () => {
    render(<App />)

    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations`,
        params: { per_page: 25, page: 1 },
      })
    })

    expect(screen.getByText(/Common Cartridge/)).toBeInTheDocument()
  })

  describe('when api call fails', () => {
    it('displays an error message', async () => {
      // @ts-expect-error
      doFetchApi.mockRejectedValue(new Error('API call failed'))

      render(<App />)

      await waitFor(() => {
        expect(screen.queryAllByText("Couldn't load previous content migrations").length).toBeGreaterThan(0)
      })
    })

    it('doesn\'t render loading spinner', async () => {
      // @ts-expect-error
      doFetchApi.mockRejectedValue(new Error('API call failed'))

      render(<App />)

      await waitFor(() => {
        expect(screen.queryAllByText("Couldn't load previous content migrations").length).toBeGreaterThan(0)
        expect(screen.queryByText('Loading')).not.toBeInTheDocument()
      })
    })
  })
})
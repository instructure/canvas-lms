/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AUPLayout} from '../../layouts/AUPLayout'
import {AUPRoutes} from '../AUPRoutes'
import {MemoryRouter, Route, Routes} from 'react-router-dom'
import {render, screen, waitFor} from '@testing-library/react'

jest.mock('@canvas/do-fetch-api-effect')

const mockApiResponse = {
  content: '<p>Test Acceptable Use Policy Content</p>',
}

describe('AUPRoutes', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('mounts without crashing', () => {
    render(
      <MemoryRouter initialEntries={['/acceptable_use_policy']}>
        <Routes>{AUPRoutes}</Routes>
      </MemoryRouter>
    )
  })

  it('renders the AcceptableUsePolicy component within AUPLayout', async () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: mockApiResponse,
      response: {ok: true},
    })
    render(
      <MemoryRouter initialEntries={['/acceptable_use_policy']}>
        <Routes>{AUPRoutes}</Routes>
      </MemoryRouter>
    )
    expect(screen.getByTitle('Loading page')).toBeInTheDocument()
    await waitFor(() => {
      const renderedContent = screen.getByTestId('aup-content')
      expect(renderedContent).not.toBeNull()
      expect(renderedContent?.innerHTML).toContain('Test Acceptable Use Policy Content')
    })
    expect(screen.queryByTitle('Loading page')).not.toBeInTheDocument()
  })

  it('renders the AUPLayout component', () => {
    render(
      <MemoryRouter initialEntries={['/acceptable_use_policy']}>
        <Routes>
          <Route path="/acceptable_use_policy" element={<AUPLayout>Test Layout</AUPLayout>} />
        </Routes>
      </MemoryRouter>
    )
    expect(screen.getByText('Test Layout')).toBeInTheDocument()
  })
})

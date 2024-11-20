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
import {render, screen, waitFor} from '@testing-library/react'
import AcceptableUsePolicy from '../AcceptableUsePolicy'
import doFetchApi from '@canvas/do-fetch-api-effect'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/alerts/react/FlashAlert')

const mockApiResponse = {
  content: '<p>Test Acceptable Use Policy Content</p>',
}

describe('AcceptableUsePolicy', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('mounts without crashing', () => {
    render(<AcceptableUsePolicy />)
  })

  it('loads content from the API and displays it', async () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: mockApiResponse,
      response: {ok: true},
    })
    render(<AcceptableUsePolicy />)
    expect(screen.getByText('Loading page')).toBeInTheDocument()
    await waitFor(() =>
      expect(screen.getByText('Test Acceptable Use Policy Content')).toBeInTheDocument()
    )
    expect(screen.queryByText('Loading page')).not.toBeInTheDocument()
  })

  it('displays an error message when content fails to load', async () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: null,
      response: {ok: false},
    })
    render(<AcceptableUsePolicy />)
    expect(screen.getByText('Loading page')).toBeInTheDocument()
    await waitFor(() =>
      expect(
        screen.getByText(
          'Unable to load the Acceptable Use Policy. Please try again later or contact support if the issue persists.'
        )
      ).toBeInTheDocument()
    )
    expect(screen.queryByText('Loading page')).not.toBeInTheDocument()
  })

  it('displays an info message when content is null', async () => {
    ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
      json: {content: null},
      response: {ok: true},
    })
    render(<AcceptableUsePolicy />)
    expect(screen.getByText('Loading page')).toBeInTheDocument()
    await waitFor(() =>
      expect(
        screen.getByText(
          'The Acceptable Use Policy is currently unavailable. Please check back later or contact support if you need further assistance.'
        )
      ).toBeInTheDocument()
    )
    expect(screen.queryByText('Loading page')).not.toBeInTheDocument()
  })
})

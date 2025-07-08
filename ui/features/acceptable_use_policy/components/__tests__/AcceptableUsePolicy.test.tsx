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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import AcceptableUsePolicy from '../AcceptableUsePolicy'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {assignLocation} from '@canvas/util/globalUtils'
import {userEvent} from '@testing-library/user-event'
import {useLocation, useNavigate, useNavigationType} from 'react-router-dom'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/alerts/react/FlashAlert')

const mockApiResponse = {
  content: '<p>Test Acceptable Use Policy Content</p>',
}

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(),
  useNavigationType: jest.fn(),
  useLocation: jest.fn(),
}))

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

describe('AcceptableUsePolicy', () => {
  const mockNavigate = jest.fn()
  const mockNavigationType = useNavigationType as jest.Mock
  const mockLocation = useLocation as jest.Mock
  beforeAll(() => {
    ;(useNavigate as jest.Mock).mockReturnValue(mockNavigate)
  })

  beforeEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
    mockNavigationType.mockReturnValue('PUSH')
    mockLocation.mockReturnValue({key: 'default'})
  })

  afterEach(() => {
    cleanup()
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
      expect(screen.getByText('Test Acceptable Use Policy Content')).toBeInTheDocument(),
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
          'Unable to load the Acceptable Use Policy. Please try again later or contact support if the issue persists.',
        ),
      ).toBeInTheDocument(),
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
          'The Acceptable Use Policy is currently unavailable. Please check back later or contact support if you need further assistance.',
        ),
      ).toBeInTheDocument(),
    )
    expect(screen.queryByText('Loading page')).not.toBeInTheDocument()
  })

  describe('navigation behavior', () => {
    it('redirects to /login when the CloseButton is clicked with no history', async () => {
      ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
        json: mockApiResponse,
        response: {ok: true},
      })
      mockNavigationType.mockReturnValue('POP')
      mockLocation.mockReturnValue({key: 'default'})
      render(<AcceptableUsePolicy />)
      await waitFor(() =>
        expect(screen.getByText('Test Acceptable Use Policy Content')).toBeInTheDocument(),
      )
      await userEvent.click(
        screen.getByTestId('close-acceptable-use-policy').querySelector('button')!,
      )
      expect(assignLocation).toHaveBeenCalledWith('/login')
      expect(mockNavigate).not.toHaveBeenCalled()
    })

    it('navigates back when the CloseButton is clicked and history exists', async () => {
      ;(doFetchApi as jest.Mock).mockResolvedValueOnce({
        json: mockApiResponse,
        response: {ok: true},
      })
      mockNavigationType.mockReturnValue('PUSH')
      mockLocation.mockReturnValue({key: 'abc123'})
      render(<AcceptableUsePolicy />)
      await waitFor(() =>
        expect(screen.getByText('Test Acceptable Use Policy Content')).toBeInTheDocument(),
      )
      await userEvent.click(
        screen.getByTestId('close-acceptable-use-policy').querySelector('button')!,
      )
      expect(mockNavigate).toHaveBeenCalledWith(-1)
      expect(assignLocation).not.toHaveBeenCalled()
    })
  })
})

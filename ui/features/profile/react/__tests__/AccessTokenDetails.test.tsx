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
import {render, screen, waitFor, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {datetimeString} from '@canvas/datetime/date-functions'
import AccessTokenDetails, {type AccessTokenDetailsProps} from '../AccessTokenDetails'
import type {Token} from '../types'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('AccessTokenDetails', () => {
  const fully_visible_token = '1~CZXKPGfzRnNrn2QUnBZGvxeuL9n9MLAhNNvRQMN6rW6xCNB2HMyBuAzGruY4yLfa'
  const visible_token = fully_visible_token.slice(0, 5) + '...'
  const loadedToken: Token = {
    app_name: 'Mock app',
    created_at: '2024-01-01T00:00:00Z',
    last_used_at: '2023-03-03T00:00:00Z',
    expires_at: '2022-02-02T00:00:00Z',
    purpose: 'Mock purpose',
    visible_token,
    can_manually_regenerate: true,
  }
  const props: AccessTokenDetailsProps = {
    loadedToken,
    url: '/url',
    userCanUpdateTokens: true,
    onClose: jest.fn(),
    onTokenLoad: jest.fn(),
  }

  beforeEach(() => {
    fakeENV.setup()
    // Use overwriteRoutes to avoid duplicate route errors when running with --randomize
    fetchMock.get(props.url, loadedToken, {overwriteRoutes: true})
  })

  afterEach(() => {
    fetchMock.reset()
    fetchMock.restore()
    fakeENV.teardown()
  })

  it('should fetch the data if the token is NOT present', async () => {
    // Reset fetchMock for this test to ensure clean state
    fetchMock.reset()
    // Re-setup the mock with overwriteRoutes to ensure it's properly configured
    fetchMock.get(props.url, loadedToken, {overwriteRoutes: true})

    render(<AccessTokenDetails {...props} loadedToken={undefined} />)

    const spinner = screen.getByLabelText(/loading/i)
    expect(spinner).toBeInTheDocument()

    // Wait for the fetch to complete with a more resilient approach
    await waitFor(
      () => {
        expect(fetchMock.called(props.url)).toBe(true)
      },
      {timeout: 2000},
    ) // Increase timeout for stability
  })

  it('should NOT fetch the data if the token is present', async () => {
    // Reset and re-setup fetchMock for this test
    fetchMock.reset()
    fetchMock.get(props.url, loadedToken, {overwriteRoutes: true})

    render(<AccessTokenDetails {...props} />)

    const spinner = screen.queryByLabelText(/loading/i)
    expect(spinner).not.toBeInTheDocument()

    // Use a more reliable approach to verify no fetch was made
    await waitFor(
      () => {
        expect(fetchMock.called(props.url)).toBe(false)
      },
      {timeout: 1000},
    )
  })

  it('should show an error if the initial fetch request fails', async () => {
    // Reset and setup fetchMock to return an error
    fetchMock.reset()
    fetchMock.get(props.url, 500, {overwriteRoutes: true})

    render(<AccessTokenDetails {...props} loadedToken={undefined} />)

    // Use findByText with a timeout to make the test more resilient
    const error = await screen.findByText(
      'Failed to load access token details. Please try again later.',
      {},
      {timeout: 2000},
    )
    expect(error).toBeInTheDocument()
  })

  it('should show the token details', () => {
    render(<AccessTokenDetails {...props} />)

    const appName = screen.getByText(loadedToken.app_name)
    const purpose = screen.getByText(loadedToken.purpose)
    const visibleToken = screen.getByText(loadedToken.visible_token)
    const createdAt = screen.getByText(datetimeString(loadedToken.created_at))
    expect(appName).toBeInTheDocument()
    expect(purpose).toBeInTheDocument()
    expect(visibleToken).toBeInTheDocument()
    expect(createdAt).toBeInTheDocument()
  })

  it('should show token warning if the token fully visible', () => {
    render(
      <AccessTokenDetails
        {...props}
        loadedToken={{...loadedToken, visible_token: fully_visible_token}}
      />,
    )

    const warning = screen.getByText(
      /once you leave this page you won't be able to retrieve the full token anymore, you'll have to regenerate it to get a new value./i,
    )
    expect(warning).toBeInTheDocument()
  })

  it('should NOT be able to regenerate the token if the user is NOT eligible', () => {
    render(<AccessTokenDetails {...props} userCanUpdateTokens={false} />)

    const regenerateButton = screen.queryByText('Regenerate Token')
    expect(regenerateButton).not.toBeInTheDocument()
  })

  it('should be able to regenerate the token if the user is eligible', async () => {
    render(<AccessTokenDetails {...props} userCanUpdateTokens={true} />)

    const regenerateButton = await screen.findByText('Regenerate Token')
    expect(regenerateButton).toBeInTheDocument()
  })

  it('should disable the regenerate button if the token is not eligible', async () => {
    render(
      <AccessTokenDetails
        {...props}
        loadedToken={{...loadedToken, can_manually_regenerate: false}}
      />,
    )

    const regenerateButton = (await screen.findByText('Regenerate Token')).closest('button')
    expect(regenerateButton).toBeDisabled()
  })

  it('should update the token if the regeneration request succeed', async () => {
    // Reset and setup fetchMock for this test
    fetchMock.reset()
    fetchMock.get(props.url, loadedToken, {overwriteRoutes: true})
    fetchMock.put(
      props.url,
      {...loadedToken, visible_token: fully_visible_token},
      {overwriteRoutes: true},
    )

    // Mock window.confirm
    const confirmSpy = jest.spyOn(window, 'confirm').mockImplementationOnce(() => true)

    render(<AccessTokenDetails {...props} />)
    const regenerateButton = await screen.findByText('Regenerate Token', {}, {timeout: 2000})

    fireEvent.click(regenerateButton)

    // Use a more reliable approach to find the new token
    const newToken = await screen.findByText(fully_visible_token, {}, {timeout: 2000})
    expect(newToken).toBeInTheDocument()
    expect(fetchMock.called(props.url, {method: 'PUT', body: {token: {regenerate: 1}}})).toBe(true)

    // Clean up the spy
    confirmSpy.mockRestore()
  })

  it('should show an error alert if the regeneration request fails', async () => {
    // Reset and setup fetchMock for this test
    fetchMock.reset()
    fetchMock.get(props.url, loadedToken, {overwriteRoutes: true})
    fetchMock.put(props.url, 500, {overwriteRoutes: true})

    // Mock window.confirm
    const confirmSpy = jest.spyOn(window, 'confirm').mockImplementationOnce(() => true)

    render(<AccessTokenDetails {...props} />)
    const regenerateButton = await screen.findByText('Regenerate Token', {}, {timeout: 2000})

    fireEvent.click(regenerateButton)

    // Use a more reliable approach to find error alerts
    const errorAlerts = await screen.findAllByText(
      'Failed to regenerate access token.',
      {},
      {timeout: 2000},
    )
    expect(errorAlerts.length).toBeTruthy()

    // Clean up the spy
    confirmSpy.mockRestore()
  })
})

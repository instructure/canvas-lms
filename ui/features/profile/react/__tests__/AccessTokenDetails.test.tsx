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
import AccessTokenDetails, {AccessTokenDetailsProps} from '../AccessTokenDetails'
import {Token} from '../types'

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
  }
  const props: AccessTokenDetailsProps = {
    loadedToken,
    url: '/url',
    isEligibleForTokenRegeneration: true,
    onClose: jest.fn(),
    onTokenLoad: jest.fn(),
  }

  beforeAll(() => {
    fetchMock.get(props.url, loadedToken)
  })

  afterEach(() => {
    fetchMock.reset()
  })

  it('should fetch the data if the token is NOT present', async () => {
    render(<AccessTokenDetails {...props} loadedToken={undefined} />)

    const spinner = screen.getByLabelText(/loading/i)
    expect(spinner).toBeInTheDocument()
    await waitFor(() => {
      expect(fetchMock.called(props.url)).toBe(true)
    })
  })

  it('should NOT fetch the data if the token is present', async () => {
    render(<AccessTokenDetails {...props} />)

    const spinner = screen.queryByLabelText(/loading/i)
    expect(spinner).not.toBeInTheDocument()
    await waitFor(() => {
      expect(fetchMock.called(props.url)).toBe(false)
    })
  })

  it('should show an error if the initial fetch request fails', async () => {
    fetchMock.get(props.url, 500, {overwriteRoutes: true})
    render(<AccessTokenDetails {...props} loadedToken={undefined} />)

    const error = await screen.findByText(
      'Failed to load access token details. Please try again later.'
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
      />
    )

    const warning = screen.getByText(
      /once you leave this page you won't be able to retrieve the full token anymore, you'll have to regenerate it to get a new value./i
    )
    expect(warning).toBeInTheDocument()
  })

  it('should NOT be able to regenerate the token if the user is NOT eligible', () => {
    render(<AccessTokenDetails {...props} isEligibleForTokenRegeneration={false} />)

    const regenerateButton = screen.queryByText('Regenerate Token')
    expect(regenerateButton).not.toBeInTheDocument()
  })

  it('should be able to regenerate the token if the user is eligible', async () => {
    render(<AccessTokenDetails {...props} isEligibleForTokenRegeneration={true} />)

    const regenerateButton = await screen.findByText('Regenerate Token')
    expect(regenerateButton).toBeInTheDocument()
  })

  it('should update the token if the regeneration request succeed', async () => {
    fetchMock.put(
      props.url,
      {...loadedToken, visible_token: fully_visible_token},
      {overwriteRoutes: true}
    )
    jest.spyOn(window, 'confirm').mockImplementationOnce(() => true)
    render(<AccessTokenDetails {...props} />)
    const regenerateButton = await screen.findByText('Regenerate Token')

    fireEvent.click(regenerateButton)

    const newToken = await screen.findByText(fully_visible_token)
    expect(newToken).toBeInTheDocument()
    expect(fetchMock.called(props.url, {method: 'PUT', body: {token: {regenerate: 1}}})).toBe(true)
  })

  it('should show an error alert if the regeneration request fails', async () => {
    fetchMock.put(props.url, 500, {overwriteRoutes: true})
    jest.spyOn(window, 'confirm').mockImplementationOnce(() => true)
    render(<AccessTokenDetails {...props} />)
    const regenerateButton = await screen.findByText('Regenerate Token')

    fireEvent.click(regenerateButton)

    const errorAlerts = await screen.findAllByText('Failed to regenerate access token.')
    expect(errorAlerts.length).toBeTruthy()
  })
})

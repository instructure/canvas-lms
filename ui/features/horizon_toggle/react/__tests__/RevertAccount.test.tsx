/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {RevertAccount} from '../RevertAccount'
import * as globalUtils from '@canvas/util/globalUtils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const server = setupServer()

jest.mock('@canvas/util/globalUtils', () => ({
  ...jest.requireActual('@canvas/util/globalUtils'),
  reloadWindow: jest.fn(),
}))

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  ...jest.requireActual('@canvas/alerts/react/FlashAlert'),
  showFlashError: jest.fn(),
}))

describe('RevertAccount', () => {
  const setup = (propOverrides = {}) => {
    const props = {
      accountId: '123',
      isHorizonAccountLocked: false,
      ...propOverrides,
    }
    return render(<RevertAccount {...props} />)
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  it('makes an API call when the Revert button is clicked', async () => {
    let capturedBody: any = null
    server.use(
      http.put('/api/v1/accounts/123', async ({request}) => {
        capturedBody = await request.json()
        return HttpResponse.json({})
      }),
    )

    setup()

    const revertButton = screen
      .getAllByText('Revert Account')
      .find(element => element.tagName === 'SPAN')

    expect(revertButton).not.toBeUndefined()
    fireEvent.click(revertButton!)

    await waitFor(() => {
      expect(capturedBody).toEqual({
        id: '123',
        account: {settings: {horizon_account: {value: false}}},
      })
      expect(globalUtils.reloadWindow).toHaveBeenCalled()
    })
  })

  it('shows an error message when API call fails', async () => {
    server.use(http.put('/api/v1/accounts/123', () => HttpResponse.error()))

    setup()

    const revertButton = screen
      .getAllByText('Revert Account')
      .find(element => element.tagName === 'SPAN')

    expect(revertButton).not.toBeUndefined()
    fireEvent.click(revertButton!)

    await waitFor(() => {
      expect(showFlashError).toHaveBeenCalledWith('Failed to revert account. Please try again.')
    })
  })
})

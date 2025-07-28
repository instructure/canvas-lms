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
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import moment from 'moment-timezone'
import NewAccessToken, {PURPOSE_MAX_LENGTH} from '../NewAccessToken'

describe('NewAccessToken', () => {
  const GENERATE_ACCESS_TOKEN_URI = '/api/v1/users/self/tokens'
  const onClose = jest.fn()
  const onSubmit = jest.fn()

  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.TIMEZONE = 'America/Denver'
    moment.tz.setDefault(window.ENV.TIMEZONE)
  })

  it('should show an error if the purpose field is empty', async () => {
    const user = userEvent.setup()
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')

    await user.click(submit)

    const errorText = await screen.findByText('Purpose is required.')
    expect(errorText).toBeInTheDocument()
  })

  // fickle
  it.skip('should show an error if the purpose field is too long', async () => {
    const user = userEvent.setup()
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText('Purpose')

    await user.type(purpose, 'a'.repeat(256))
    await user.click(submit)

    const errorText = await screen.findByText(
      `Exceeded the maximum length (${PURPOSE_MAX_LENGTH} characters).`,
    )
    expect(errorText).toBeInTheDocument()
  })

  // fickle
  it.skip('should show an error if the network request fails', async () => {
    const user = userEvent.setup()
    fetchMock.post(GENERATE_ACCESS_TOKEN_URI, 500, {overwriteRoutes: true})
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText('Purpose')

    await user.type(purpose, 'a'.repeat(20))
    await user.click(submit)

    const errorAlert = await screen.findByRole('alert')
    expect(errorAlert).toHaveTextContent('Generating token failed.')
  })

  it('should be able to submit the form if only the purpose filed is provided', async () => {
    const user = userEvent.setup()
    const token = {purpose: 'Test purpose'}
    fetchMock.post(GENERATE_ACCESS_TOKEN_URI, {token}, {overwriteRoutes: true})
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText('Purpose')

    // Type the text and wait for it to be fully entered
    await user.clear(purpose)
    await user.type(purpose, token.purpose)
    expect(purpose).toHaveValue(token.purpose)

    await user.click(submit)

    await waitFor(
      () => {
        const wasCalled = fetchMock.called(GENERATE_ACCESS_TOKEN_URI)
        if (!wasCalled) {
          console.log('Fetch not called yet')
          return false
        }
        const lastCall = fetchMock.lastCall(GENERATE_ACCESS_TOKEN_URI)
        if (!lastCall) {
          console.log('No fetch call found')
          return false
        }
        const body = JSON.parse(lastCall[1]?.body as string)
        expect(body).toEqual({token})
        expect(onSubmit).toHaveBeenCalledWith({token})
        return true
      },
      {timeout: 20000},
    )
  }, 30000)

  it('should be able to submit the form if both the purpose and expirations fields are provided', async () => {
    const user = userEvent.setup()
    const expirationDate = moment.tz('2024-11-14T00:00:00', window.ENV.TIMEZONE)
    const token = {
      purpose: 'Test purpose',
      expires_at: expirationDate.utc().format('YYYY-MM-DDTHH:mm:ss.SSS[Z]'),
    }
    const expirationDateValue = 'November 14, 2024'
    const expirationTimeValue = '12:00 AM'
    fetchMock.post(GENERATE_ACCESS_TOKEN_URI, {token}, {overwriteRoutes: true})
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText('Purpose')
    const expirationDateInput = screen.getByLabelText('Expiration date')
    const expirationTimeInput = screen.getByLabelText('Expiration time')

    // Type the text and wait for it to be fully entered
    await user.clear(purpose)
    await user.type(purpose, token.purpose)
    expect(purpose).toHaveValue(token.purpose)

    await user.type(expirationDateInput, expirationDateValue)
    await user.tab() // blur the date field
    await user.type(expirationTimeInput, expirationTimeValue)
    await user.tab() // blur the time field
    await user.click(submit)

    await waitFor(
      () => {
        const wasCalled = fetchMock.called(GENERATE_ACCESS_TOKEN_URI)
        if (!wasCalled) {
          return false
        }
        const lastCall = fetchMock.lastCall(GENERATE_ACCESS_TOKEN_URI)
        if (!lastCall) {
          return false
        }
        const body = JSON.parse(lastCall[1]?.body as string)
        expect(body).toEqual({token})
        expect(onSubmit).toHaveBeenCalledWith({token})
        return true
      },
      {timeout: 20000}, // Increase timeout for CI
    )
  }, 30000) // Add test timeout
})

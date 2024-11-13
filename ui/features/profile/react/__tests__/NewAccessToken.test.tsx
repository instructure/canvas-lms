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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import NewAccessToken, {PURPOSE_MAX_LENGTH} from '../NewAccessToken'

describe('NewAccessToken', () => {
  const GENERATE_ACCESS_TOKEN_URI = '/api/v1/users/self/tokens'
  const onClose = jest.fn()
  const onSubmit = jest.fn()

  it('should show an error if the purpose field is empty', async () => {
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')

    fireEvent.click(submit)

    const errorText = await screen.findByText('Purpose is required.')
    expect(errorText).toBeInTheDocument()
  })

  it('should show an error if the purpose field is too long', async () => {
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText('Purpose')

    fireEvent.input(purpose, {target: {value: 'a'.repeat(256)}})
    fireEvent.click(submit)

    const errorText = await screen.findByText(
      `Exceeded the maximum length (${PURPOSE_MAX_LENGTH} characters).`
    )
    expect(errorText).toBeInTheDocument()
  })

  it('should show an error if the network request fails', async () => {
    fetchMock.post(GENERATE_ACCESS_TOKEN_URI, 500, {overwriteRoutes: true})
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText('Purpose')

    fireEvent.input(purpose, {target: {value: 'a'.repeat(20)}})
    fireEvent.click(submit)

    const errorAlerts = await screen.findAllByText('Generating token failed.')
    expect(errorAlerts.length).toBeTruthy()
  })

  it('should be able to submit the form if only the purpose filed is provided', async () => {
    const token = {purpose: 'Test purpose'}
    fetchMock.post(GENERATE_ACCESS_TOKEN_URI, token, {overwriteRoutes: true})
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText('Purpose')

    fireEvent.input(purpose, {target: {value: token.purpose}})
    fireEvent.click(submit)

    await waitFor(() => {
      expect(fetchMock.called(GENERATE_ACCESS_TOKEN_URI, {method: 'POST', body: {token}})).toBe(
        true
      )
      expect(onSubmit).toHaveBeenCalledWith(token)
    })
  })

  it('should be able to submit the form if both the purpose and expirations fields are provided', async () => {
    const token = {purpose: 'Test purpose', expires_at: '2024-11-14T00:00:00.000Z'}
    const expirationDateValue = 'November 14, 2024'
    const expirationTimeValue = '12:00 AM'
    fetchMock.post(GENERATE_ACCESS_TOKEN_URI, token, {overwriteRoutes: true})
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText('Purpose')
    const expirationDate = screen.getByLabelText('Expiration date')
    const expirationTime = screen.getByLabelText('Expiration time')

    fireEvent.input(purpose, {target: {value: token.purpose}})
    fireEvent.input(expirationDate, {target: {value: expirationDateValue}})
    fireEvent.blur(expirationDate)
    fireEvent.input(expirationTime, {target: {value: expirationTimeValue}})
    fireEvent.blur(expirationTime)
    fireEvent.click(submit)

    await waitFor(() => {
      expect(fetchMock.called(GENERATE_ACCESS_TOKEN_URI, {method: 'POST', body: {token}})).toBe(
        true
      )
      expect(onSubmit).toHaveBeenCalledWith(token)
    })
  })
})

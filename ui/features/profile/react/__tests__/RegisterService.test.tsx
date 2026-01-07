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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import RegisterService, {serviceConfigByName, USERNAME_MAX_LENGTH} from '../RegisterService'

const server = setupServer()

describe('RegisterService', () => {
  const onClose = vi.fn()
  const onSubmit = vi.fn()
  const mockUrl = 'mock-url'
  const USER_SERVICE_URI = '/profile/user_services'

  beforeAll(() => {
    window.ENV.google_drive_oauth_url = mockUrl
    server.listen()
  })

  afterAll(() => {
    // @ts-expect-error
    window.ENV = {}
    server.close()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('when the service is Google Drive', () => {
    const serviceName = 'google_drive'
    const config = serviceConfigByName[serviceName]

    it('should render correctly', () => {
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const title = screen.getByText(config.title)
      const description = screen.getByText(config.description)
      const logo = screen.getByAltText(config.image.alt)
      const button = screen.getByLabelText('Authorize Google Drive Access')

      expect(title).toBeInTheDocument()
      expect(description).toBeInTheDocument()
      expect(logo).toBeInTheDocument()
      expect(button).toBeInTheDocument()
      expect(button).toHaveAttribute('href', mockUrl)
    })
  })

  describe('when the service is Diigo', () => {
    const serviceName = 'diigo'
    const config = serviceConfigByName[serviceName]

    it('should render correctly', () => {
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const title = screen.getByText(config.title)
      const description = screen.getByText(config.description)
      const logo = screen.getByAltText(config.image.alt)
      const username = screen.getByLabelText('Username')
      const password = screen.getByLabelText('Password')
      const button = screen.getByLabelText('Save Login')

      expect(title).toBeInTheDocument()
      expect(description).toBeInTheDocument()
      expect(logo).toBeInTheDocument()
      expect(username).toBeInTheDocument()
      expect(password).toBeInTheDocument()
      expect(button).toBeInTheDocument()
    })

    it('should show an error message if the username field is empty', async () => {
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const button = screen.getByLabelText('Save Login')

      fireEvent.click(button)

      const errorText = await screen.findByText('This field is required.')
      expect(errorText).toBeInTheDocument()
    })

    it('should show an error message if the username is too long', async () => {
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const username = screen.getByLabelText('Username')
      const button = screen.getByLabelText('Save Login')

      fireEvent.input(username, {target: {value: 'a'.repeat(256)}})
      fireEvent.click(button)

      const errorText = await screen.findByText(
        `Exceeded the maximum length (${USERNAME_MAX_LENGTH} characters).`,
      )
      expect(errorText).toBeInTheDocument()
    })

    it('should show an error if the network request fails', async () => {
      server.use(
        http.post(USER_SERVICE_URI, () => {
          return new HttpResponse(null, {status: 500})
        }),
      )
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const username = screen.getByLabelText('Username')
      const button = screen.getByLabelText('Save Login')

      fireEvent.input(username, {target: {value: 'a'.repeat(20)}})
      fireEvent.click(button)

      const errorAlerts = await screen.findAllByText(
        'Registration failed. Check the username and/or password, and try again.',
      )
      expect(errorAlerts.length).toBeTruthy()
    })

    it('should be able to submit the form if it is valid', async () => {
      const requestBodyCapture = vi.fn()
      server.use(
        http.post(USER_SERVICE_URI, async ({request}) => {
          const body = await request.json()
          requestBodyCapture(body)
          return new HttpResponse(null, {status: 200})
        }),
      )
      const usernameValue = 'test-username'
      const passwordValue = 'test-password'
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const username = screen.getByLabelText('Username')
      const password = screen.getByLabelText('Password')
      const button = screen.getByLabelText('Save Login')

      fireEvent.input(username, {target: {value: usernameValue}})
      fireEvent.input(password, {target: {value: passwordValue}})
      fireEvent.click(button)

      await waitFor(() => {
        expect(requestBodyCapture).toHaveBeenCalledWith({
          user_service: {service: serviceName, user_name: usernameValue, password: passwordValue},
        })
        expect(onSubmit).toHaveBeenCalled()
      })
    })
  })
})

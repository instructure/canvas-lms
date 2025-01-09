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
import RegisterService, {serviceConfigByName, USERNAME_MAX_LENGTH} from '../RegisterService'

describe('RegisterService', () => {
  const onClose = jest.fn()
  const onSubmit = jest.fn()
  const mockUrl = 'mock-url'
  const USER_SERVICE_URI = '/profile/user_services'

  beforeAll(() => {
    window.ENV.google_drive_oauth_url = mockUrl
  })

  afterAll(() => {
    // @ts-expect-error
    window.ENV = {}
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

  describe('when the service is Skype', () => {
    const serviceName = 'skype'
    const config = serviceConfigByName[serviceName]

    it('should render correctly', () => {
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const title = screen.getByText(config.title)
      const description = screen.getByText(config.description)
      const logo = screen.getByAltText(config.image.alt)
      const skypeName = screen.getByLabelText('Skype Name')
      const button = screen.getByLabelText('Save Skype Name')

      expect(title).toBeInTheDocument()
      expect(description).toBeInTheDocument()
      expect(logo).toBeInTheDocument()
      expect(skypeName).toBeInTheDocument()
      expect(button).toBeInTheDocument()
    })

    it('should show an error message if the Skype Name is empty', async () => {
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const button = screen.getByLabelText('Save Skype Name')

      fireEvent.click(button)

      const errorText = await screen.findByText('This field is required.')
      expect(errorText).toBeInTheDocument()
    })

    it('should show an error message if the Skype Name is too long', async () => {
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const skypeName = screen.getByLabelText('Skype Name')
      const button = screen.getByLabelText('Save Skype Name')

      fireEvent.input(skypeName, {target: {value: 'a'.repeat(256)}})
      fireEvent.click(button)

      const errorText = await screen.findByText(
        `Exceeded the maximum length (${USERNAME_MAX_LENGTH} characters).`,
      )
      expect(errorText).toBeInTheDocument()
    })

    it('should show an error if the network request fails', async () => {
      fetchMock.post(USER_SERVICE_URI, 500, {overwriteRoutes: true})
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const skypeName = screen.getByLabelText('Skype Name')
      const button = screen.getByLabelText('Save Skype Name')

      fireEvent.input(skypeName, {target: {value: 'a'.repeat(20)}})
      fireEvent.click(button)

      const errorAlerts = await screen.findAllByText(
        'Registration failed. Check the username and/or password, and try again.',
      )
      expect(errorAlerts.length).toBeTruthy()
    })

    it('should be able to submit the form if it is valid', async () => {
      fetchMock.post(USER_SERVICE_URI, 200, {overwriteRoutes: true})
      const skypeNameValue = 'test-skype-name'
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const skypeName = screen.getByLabelText('Skype Name')
      const button = screen.getByLabelText('Save Skype Name')

      fireEvent.input(skypeName, {target: {value: skypeNameValue}})
      fireEvent.click(button)

      await waitFor(() => {
        fetchMock.called(USER_SERVICE_URI, {
          method: 'POST',
          body: {user_service: {service: serviceName, user_name: skypeNameValue}},
        })
        expect(onSubmit).toHaveBeenCalled()
      })
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

    it('should show an error message if the Skype Name is empty', async () => {
      render(<RegisterService serviceName={serviceName} onSubmit={onSubmit} onClose={onClose} />)
      const button = screen.getByLabelText('Save Login')

      fireEvent.click(button)

      const errorText = await screen.findByText('This field is required.')
      expect(errorText).toBeInTheDocument()
    })

    it('should show an error message if the Skype Name is too long', async () => {
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
      fetchMock.post(USER_SERVICE_URI, 500, {overwriteRoutes: true})
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
      fetchMock.post(USER_SERVICE_URI, 200, {overwriteRoutes: true})
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
        fetchMock.called(USER_SERVICE_URI, {
          method: 'POST',
          body: {
            user_service: {service: serviceName, user_name: usernameValue, password: passwordValue},
          },
        })
        expect(onSubmit).toHaveBeenCalled()
      })
    })
  })
})

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

import {assignLocation} from '@canvas/util/globalUtils'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {NewLoginProvider} from '../../context'
import {cancelOtpRequest, verifyOtpRequest} from '../../services'
import OtpForm from '../OtpForm'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

jest.mock('../../services', () => ({
  initiateOtpRequest: jest
    .fn()
    .mockResolvedValue(
      new Promise(resolve =>
        setTimeout(
          () => resolve({status: 200, data: {otp_sent: true, otp_communication_channel_id: 123}}),
          500,
        ),
      ),
    ),
  verifyOtpRequest: jest.fn(),
  cancelOtpRequest: jest.fn().mockResolvedValue({status: 200}),
}))

describe('OtpForm', () => {
  const setup = () => {
    render(
      <MemoryRouter>
        <NewLoginProvider>
          <OtpForm />
        </NewLoginProvider>
      </MemoryRouter>,
    )
  }

  describe('ui rendering', () => {
    it('displays OTP form after initiation', async () => {
      setup()
      await waitFor(() =>
        expect(screen.getByText('Multi-Factor Authentication')).toBeInTheDocument(),
      )
      expect(screen.getByTestId('otp-input')).toBeInTheDocument()
    })

    it('displays the correct OTP input label', async () => {
      setup()
      await waitFor(() => expect(screen.getByLabelText(/Verification Code/i)).toBeInTheDocument())
    })
  })

  describe('form validation', () => {
    it('does not submit if OTP field is empty', async () => {
      setup()
      await waitFor(() => expect(screen.getByTestId('verify-button')).toBeInTheDocument())
      const submitButton = screen.getByTestId('verify-button')
      await userEvent.click(submitButton)
      expect(await screen.findByTestId('otp-input')).toHaveAttribute('aria-invalid', 'true')
    })

    it('shows required validation message and asterisk when submitting an empty OTP', async () => {
      setup()
      await waitFor(() => expect(screen.getByTestId('verify-button')).toBeInTheDocument())
      const submitButton = screen.getByTestId('verify-button')
      await userEvent.click(submitButton)
      const errorMessage = await screen.findByText('Please enter the code sent to your phone.')
      expect(errorMessage).toBeInTheDocument()
      const requiredLabels = screen.getAllByText(/\*$/)
      expect(requiredLabels).not.toHaveLength(0)
    })
  })

  describe('otp flow', () => {
    it('validates empty OTP field on submit', async () => {
      setup()
      await waitFor(() => expect(screen.getByTestId('otp-input')).toBeInTheDocument())
      await userEvent.click(screen.getByTestId('verify-button'))
      expect(
        await screen.findByText('Please enter the code sent to your phone.'),
      ).toBeInTheDocument()
    })

    it('submits valid OTP and redirects', async () => {
      ;(verifyOtpRequest as jest.Mock).mockResolvedValueOnce({
        status: 200,
        data: {location: '/dashboard'},
      })
      setup()
      await waitFor(() => expect(screen.getByTestId('otp-input')).toBeInTheDocument())
      await userEvent.type(screen.getByTestId('otp-input'), '123456')
      await userEvent.click(screen.getByTestId('verify-button'))
      await waitFor(() => expect(assignLocation).toHaveBeenCalledWith('/dashboard'))
    })
  })

  describe('error handling', () => {
    it('shows error when OTP verification fails due to invalid code', async () => {
      ;(verifyOtpRequest as jest.Mock).mockRejectedValueOnce({response: {status: 422}})
      setup()
      await waitFor(() => expect(screen.getByTestId('otp-input')).toBeInTheDocument())
      await userEvent.type(screen.getByTestId('otp-input'), '654321')
      await userEvent.click(screen.getByTestId('verify-button'))
      expect(
        await screen.findByText('Invalid verification code, please try again.'),
      ).toBeInTheDocument()
    })

    it('shows error when OTP verification encounters a server error', async () => {
      ;(verifyOtpRequest as jest.Mock).mockRejectedValueOnce(new Error('Server Error'))
      setup()
      await waitFor(() => expect(screen.getByTestId('otp-input')).toBeInTheDocument())
      await userEvent.type(screen.getByTestId('otp-input'), '987654')
      await userEvent.click(screen.getByTestId('verify-button'))
      const errorMessages = await screen.findAllByText(
        'Something went wrong while verifying the code. Please try again.',
      )
      expect(errorMessages.length).toBeGreaterThan(0)
    })
  })

  describe('cancel otp', () => {
    it('calls cancelOtpRequest when cancel button is clicked', async () => {
      setup()
      await waitFor(() => expect(screen.getByTestId('cancel-button')).toBeInTheDocument())
      await userEvent.click(screen.getByTestId('cancel-button'))
      await waitFor(() => expect(cancelOtpRequest).toHaveBeenCalled())
    })
  })
})

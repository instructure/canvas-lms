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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {fireEvent, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React, {createRef} from 'react'
import CreateTicketForm from '../CreateTicketForm'

jest.mock('@canvas/do-fetch-api-effect')

describe('CreateTicketForm', () => {
  const onCancel = jest.fn()
  const onSubmit = jest.fn()

  const props = {onCancel, onSubmit}

  const mockEnv = (overrides: Partial<typeof window.ENV> = {}) => {
    ;(window.ENV as any) = {
      ...window.ENV,
      ...overrides,
    }
  }

  beforeEach(() => {
    // default mock for tests
    mockEnv({
      current_user_id: '64', // intentionally a string and not a number
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('rendering', () => {
    it('focuses on subject field when form renders', () => {
      const {getByTestId} = render(<CreateTicketForm {...props} />)
      const subjectInput = getByTestId('subject-input')
      expect(subjectInput).toHaveFocus()
    })

    it('displays subject and description input fields with labels', () => {
      const {getByText, getByTestId} = render(<CreateTicketForm {...props} />)
      expect(getByTestId('subject-input')).toBeInTheDocument()
      expect(getByText('Subject')).toBeVisible()
      expect(getByTestId('description-input')).toBeInTheDocument()
      expect(getByText('Description')).toBeVisible()
    })

    it('shows severity select field with label and available options', async () => {
      const {getByText, getByTestId} = render(<CreateTicketForm {...props} />)
      expect(getByTestId('severity-select')).toBeInTheDocument()
      expect(getByText('How is this affecting you?')).toBeVisible()
      await userEvent.click(getByTestId('severity-select'))
      expect(getByText('Just a casual question, comment, idea, or suggestion')).toBeVisible()
      expect(getByText('I need some help, but it is not urgent')).toBeVisible()
      expect(getByText('Something is broken, but I can work around it for now')).toBeVisible()
      expect(getByText('I cannot get things done until I hear back from you')).toBeVisible()
      expect(getByText('EXTREME CRITICAL EMERGENCY!')).toBeVisible()
    })

    it('includes cancel and submit buttons with labels', () => {
      const {getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      expect(getByTestId('cancel-button')).toBeVisible()
      expect(getByText('Cancel')).toBeVisible()
      expect(getByTestId('submit-button')).toBeVisible()
      expect(getByText('Submit Ticket')).toBeVisible()
    })

    it('hides optional email field if user is logged in', () => {
      const {queryByText, queryByTestId} = render(<CreateTicketForm {...props} />)
      expect(queryByTestId('email-input')).not.toBeInTheDocument()
      expect(queryByText('Your email address')).not.toBeInTheDocument()
    })

    it('displays optional email field if user is logged out', () => {
      mockEnv({current_user_id: null})
      const {getByText, getByTestId} = render(<CreateTicketForm {...props} />)
      expect(getByTestId('email-input')).toBeVisible()
      expect(getByText('Your email address')).toBeVisible()
    })
  })

  describe('validation', () => {
    beforeEach(() => {
      // Reset all mocks before each test
      jest.clearAllMocks()

      // Mock doFetchApi to prevent actual API calls
      ;(doFetchApi as jest.Mock).mockImplementation(() => {
        return Promise.resolve({
          response: {status: 200},
          json: {message: 'Success'},
        })
      })
    })

    it('prevents submission if required fields are empty', async () => {
      const {getByText, findByText} = render(<CreateTicketForm {...props} />)

      // Click submit with empty fields
      fireEvent.click(getByText('Submit Ticket'))

      // Verify that validation errors appear for required fields
      expect(await findByText('Subject is required.')).toBeInTheDocument()

      // Since validation fails, the form submission API should not be called
      expect(doFetchApi).not.toHaveBeenCalled()
    })

    it('validates fields progressively when submitting the form', async () => {
      const {findByText, getByTestId, getByText, queryByText} = render(
        <CreateTicketForm {...props} />,
      )
      // submit with all fields empty
      await userEvent.click(getByTestId('submit-button'))
      expect(await findByText('Subject is required.')).toBeVisible()
      // subject field
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      await userEvent.click(getByTestId('submit-button'))
      expect(queryByText('Subject is required.')).toBeNull()
      expect(await findByText('Description is required.')).toBeVisible()
      // description field
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('submit-button'))
      expect(queryByText('Description is required.')).toBeNull()
      expect(await findByText('Please select an option.')).toBeVisible()
      // selection field
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.click(getByTestId('submit-button'))
      expect(queryByText('Please select an option.')).toBeNull()
    })

    it('ensures email field is correctly formatted when provided', async () => {
      mockEnv({current_user_id: null})
      const {findByText, getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // subject field
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      // description field
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      // severity field
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      // optional email field
      await userEvent.type(getByTestId('email-input'), 'invalid-email-address')
      // submit
      await userEvent.click(getByTestId('submit-button'))
      expect(await findByText('Please provide a valid email address.')).toBeVisible()
    })

    it('clears severity error and updates value when a valid selection is made', async () => {
      const {getByTestId, getByText, queryByText} = render(<CreateTicketForm {...props} />)
      // subject field
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      // description field
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      // submit
      await userEvent.click(getByTestId('submit-button'))
      // selection field
      expect(getByText('Please select an option.')).toBeVisible()
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      expect(queryByText('Please select an option.')).toBeNull()
      expect(getByTestId('severity-select')).toHaveValue(
        'Just a casual question, comment, idea, or suggestion',
      )
    })
  })

  describe('form submission requests', () => {
    it('sends correct payload when user is logged out', async () => {
      mockEnv({
        current_user_id: null, // will populate when logged in
        // @ts-expect-error: context_asset_string can be null in real scenarios, even if TypeScript doesn’t allow it
        context_asset_string: null, // will populate if in course, for example, null otherwise
        // @ts-expect-error: current_user_roles can be null in real scenarios even if TypeScript doesn’t allow it
        current_user_roles: null, // will populate when logged in
      })
      ;(doFetchApi as jest.Mock).mockResolvedValue({
        response: {status: 200},
        json: {logged: true, id: '10033'},
      })
      const {getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // fill and submit form
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.type(getByTestId('email-input'), 'test@instructure.com')
      await userEvent.click(getByTestId('submit-button'))
      const payload = {
        error: expect.objectContaining({
          subject: 'Test subject',
          comments: 'Test description',
          user_perceived_severity: 'just_a_comment',
          email: 'test@instructure.com', // optional
          url: window.location.toString(), // e.g. http://localhost:3000/login/canvas#help
          context_asset_string: null,
          user_roles: undefined,
        }),
      }
      // verify api call
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/error_reports',
        method: 'POST',
        body: payload,
      })
    })

    it('sends correct payload when user is logged in', async () => {
      mockEnv({
        context_asset_string: 'course_7', // this will be populated if in course, for example
        current_user_roles: ['user', 'student', 'teacher', 'admin', 'root_admin'], // ENV.current_user_roles is an array to begin with
      })
      ;(doFetchApi as jest.Mock).mockResolvedValue({
        response: {status: 200},
        json: {logged: true, id: '10033'},
      })
      const {getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // fill and submit form
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.click(getByTestId('submit-button'))
      const payload = {
        error: expect.objectContaining({
          subject: 'Test subject',
          comments: 'Test description',
          user_perceived_severity: 'just_a_comment',
          email: '',
          url: window.location.toString(),
          context_asset_string: 'course_7',
          user_roles: 'user,student,teacher,admin,root_admin', // payload requires comma delimited string of values
        }),
      }
      // verify api call
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/error_reports',
        method: 'POST',
        body: payload,
      })
    })
  })

  describe('form behavior on submission', () => {
    beforeEach(() => {
      ;(doFetchApi as jest.Mock).mockReset()
    })

    it('disables all form fields during submission', async () => {
      ;(doFetchApi as jest.Mock).mockImplementation(
        () =>
          new Promise(resolve =>
            setTimeout(() => {
              resolve({
                response: {status: 200},
                json: {logged: true, id: '10033'},
              })
            }, 500),
          ),
      )
      const {getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // fill and submit form
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.click(getByTestId('submit-button'))
      // disabled check
      await waitFor(() => {
        expect(getByTestId('subject-input')).toBeDisabled()
        expect(getByTestId('description-input')).toBeDisabled()
        expect(getByTestId('severity-select')).toBeDisabled()
        expect(getByTestId('submit-button')).toBeDisabled()
      })
      // ensure fields are re-enabled after submission
      await waitFor(() => {
        expect(getByTestId('submit-button')).not.toBeDisabled()
      })
    })

    it('shows success message when ticket is submitted successfully', async () => {
      ;(doFetchApi as jest.Mock).mockResolvedValue({
        response: {status: 200},
        json: {message: 'Success'},
      })
      const {getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // fill and submit form
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.click(getByTestId('submit-button'))
      // verify success callback
      await waitFor(() => expect(onSubmit).toHaveBeenCalled())
      // verify success flash message
      await waitFor(() =>
        expect(document.querySelector('.flashalert-message')).toHaveTextContent(
          'Ticket successfully submitted.',
        ),
      )
    })

    it('displays error message if submission fails', async () => {
      ;(doFetchApi as jest.Mock).mockResolvedValue({
        response: {status: 400},
        json: {message: 'Server error occurred'},
      })
      const {findByText, getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // fill and submit form
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.click(getByTestId('submit-button'))
      // verify error message
      expect(await findByText('Server error occurred')).toBeVisible()
    })
  })

  describe('form reset and cancellation', () => {
    it('clears form and triggers cancel event when clicking cancel', async () => {
      const {getByTestId} = render(<CreateTicketForm {...props} />)
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      await userEvent.click(getByTestId('cancel-button'))
      expect(getByTestId('subject-input')).toHaveValue('')
      expect(onCancel).toHaveBeenCalled()
    })

    it('allows parent component to reset form via ref', () => {
      const ref = createRef<{resetForm: () => void}>()
      const {getByTestId} = render(<CreateTicketForm ref={ref} {...props} />)
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      ref.current?.resetForm()
      expect(getByTestId('subject-input')).toHaveValue('')
    })
  })

  describe('Captcha', () => {
    it('loads script when user is not logged in', () => {
      mockEnv({current_user_id: null})
      render(<CreateTicketForm {...props} />)
      const script = document.querySelector(
        'head script[src="https://www.google.com/recaptcha/api.js"]',
      )
      expect(script).toBeInTheDocument()
    })

    it('removes script on unmount when user is not logged in', () => {
      mockEnv({current_user_id: null})
      const {unmount} = render(<CreateTicketForm {...props} />)
      unmount()
      const script = document.querySelector(
        'head script[src="https://www.google.com/recaptcha/api.js"]',
      )
      expect(script).toBeNull()
    })

    it('does not load script when user is logged in', () => {
      mockEnv({current_user_id: '64'})
      render(<CreateTicketForm {...props} />)
      const script = document.querySelector(
        'head script[src="https://www.google.com/recaptcha/api.js"]',
      )
      expect(script).toBeNull()
    })
  })
})

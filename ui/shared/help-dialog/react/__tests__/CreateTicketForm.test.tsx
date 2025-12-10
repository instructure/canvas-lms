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

import {fireEvent, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React, {createRef} from 'react'
import CreateTicketForm from '../CreateTicketForm'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('CreateTicketForm', () => {
  const onCancel = jest.fn()
  const onSubmit = jest.fn()

  const props = {onCancel, onSubmit}

  // Track captured request for verification
  let lastCapturedRequest: {path: string; method: string; body?: any} | null = null

  const mockEnv = (overrides: Partial<typeof window.ENV> = {}) => {
    ;(window.ENV as any) = {
      ...window.ENV,
      ...overrides,
    }
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    lastCapturedRequest = null
    // Default handler for error_reports POST
    server.use(
      http.post('/error_reports', async ({request}) => {
        lastCapturedRequest = {
          path: '/error_reports',
          method: 'POST',
          body: await request.json(),
        }
        return HttpResponse.json({logged: true, id: '10033'})
      }),
    )
    // default mock for tests
    mockEnv({
      current_user_id: '64', // intentionally a string and not a number
    })
  })

  afterEach(() => {
    server.resetHandlers()
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
    })

    it('prevents submission if required fields are empty', async () => {
      const {getByText, findByText} = render(<CreateTicketForm {...props} />)

      // Click submit with empty fields
      fireEvent.click(getByText('Submit Ticket'))

      // Verify that validation errors appear for required fields
      expect(await findByText('Subject is required.')).toBeInTheDocument()

      // Since validation fails, the form submission API should not be called
      expect(lastCapturedRequest).toBeNull()
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
        // @ts-expect-error: context_asset_string can be null in real scenarios, even if TypeScript doesn't allow it
        context_asset_string: null, // will populate if in course, for example, null otherwise
        // @ts-expect-error: current_user_roles can be null in real scenarios even if TypeScript doesn't allow it
        current_user_roles: null, // will populate when logged in
      })
      const {getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // fill and submit form
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.type(getByTestId('email-input'), 'test@instructure.com')
      await userEvent.click(getByTestId('submit-button'))
      // verify api call
      await waitFor(() => {
        expect(lastCapturedRequest).not.toBeNull()
      })
      expect(lastCapturedRequest!.path).toBe('/error_reports')
      expect(lastCapturedRequest!.method).toBe('POST')
      expect(lastCapturedRequest!.body.error).toMatchObject({
        subject: 'Test subject',
        comments: 'Test description',
        user_perceived_severity: 'just_a_comment',
        email: 'test@instructure.com',
        context_asset_string: null,
      })
    })

    it('sends correct payload when user is logged in', async () => {
      mockEnv({
        context_asset_string: 'course_7', // this will be populated if in course, for example
        current_user_roles: ['user', 'student', 'teacher', 'admin', 'root_admin'], // ENV.current_user_roles is an array to begin with
      })
      const {getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // fill and submit form
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.click(getByTestId('submit-button'))
      // verify api call
      await waitFor(() => {
        expect(lastCapturedRequest).not.toBeNull()
      })
      expect(lastCapturedRequest!.path).toBe('/error_reports')
      expect(lastCapturedRequest!.method).toBe('POST')
      expect(lastCapturedRequest!.body.error).toMatchObject({
        subject: 'Test subject',
        comments: 'Test description',
        user_perceived_severity: 'just_a_comment',
        email: '',
        context_asset_string: 'course_7',
        user_roles: 'user,student,teacher,admin,root_admin',
      })
    })
  })

  describe('form behavior on submission', () => {
    it('disables all form fields during submission', async () => {
      // Use a delayed response to test the loading state
      server.use(
        http.post('/error_reports', async ({request}) => {
          await new Promise(resolve => setTimeout(resolve, 500))
          lastCapturedRequest = {
            path: '/error_reports',
            method: 'POST',
            body: await request.json(),
          }
          return HttpResponse.json({logged: true, id: '10033'})
        }),
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
      // Override default handler with error response - must use resetHandlers first
      server.resetHandlers()
      server.use(
        http.post('/error_reports', () =>
          HttpResponse.json({message: 'Server error occurred'}, {status: 400}),
        ),
      )
      const {findByTestId, getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // fill and submit form
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      await userEvent.click(getByTestId('submit-button'))
      // verify error message is shown (component shows it in an Alert with data-testid="error-message")
      const errorAlert = await findByTestId('error-message')
      expect(errorAlert).toBeVisible()
      expect(errorAlert).toHaveTextContent(/An unexpected error occurred/)
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

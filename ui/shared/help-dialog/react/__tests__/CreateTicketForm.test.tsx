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
    mockEnv({current_user_id: '64'})
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('rendering tests', () => {
    it('renders all required field labels', () => {
      const {getByText} = render(<CreateTicketForm {...props} />)
      expect(getByText('Subject')).toBeVisible()
      expect(getByText('Description')).toBeVisible()
      expect(getByText('How is this affecting you?')).toBeVisible()
    })

    it('does not render the email field when current_user_id is set', () => {
      const {queryByTestId} = render(<CreateTicketForm {...props} />)
      expect(queryByTestId('email-input')).toBeNull()
    })

    it('renders the email field if current_user_id is not set', () => {
      mockEnv({current_user_id: null})
      const {getByText} = render(<CreateTicketForm {...props} />)
      expect(getByText('Your email address')).toBeVisible()
    })

    it('renders all severity options', async () => {
      const {getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      await userEvent.click(getByTestId('severity-select'))
      expect(getByText('Just a casual question, comment, idea, or suggestion')).toBeVisible()
      expect(getByText('I need some help, but it is not urgent')).toBeVisible()
      expect(getByText('Something is broken, but I can work around it for now')).toBeVisible()
      expect(getByText('I cannot get things done until I hear back from you')).toBeVisible()
      expect(getByText('EXTREME CRITICAL EMERGENCY!')).toBeVisible()
    })

    it('renders the form action buttons', () => {
      const {getByTestId} = render(<CreateTicketForm {...props} />)
      expect(getByTestId('cancel-button')).toBeVisible()
      expect(getByTestId('submit-button')).toBeVisible()
    })
  })

  describe('validation tests', () => {
    it('validates required fields progressively on submission', async () => {
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

    it('validates email format when provided', async () => {
      mockEnv({current_user_id: null})
      const {findByText, getByTestId, getByText} = render(<CreateTicketForm {...props} />)
      // subject field
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      // description field
      fireEvent.change(getByTestId('description-input'), {target: {value: 'Test description'}})
      // selection field
      await userEvent.click(getByTestId('severity-select'))
      await userEvent.click(getByText('Just a casual question, comment, idea, or suggestion'))
      // email field
      fireEvent.change(getByTestId('email-input'), {target: {value: 'invalid-email-address'}})
      // submit
      await userEvent.click(getByTestId('submit-button'))
      expect(await findByText('Please provide a valid email address.')).toBeVisible()
    })

    it('updates severity value and clears error on valid selection', async () => {
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

  describe('submission tests', () => {
    beforeEach(() => {
      ;(doFetchApi as jest.Mock).mockReset()
    })

    it('disables all form fields during submission', async () => {
      ;(doFetchApi as jest.Mock).mockImplementation(
        () =>
          new Promise(resolve =>
            setTimeout(() => {
              resolve({response: {status: 200}, json: {message: 'Success'}})
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

    it('calls the API with the correct payload', async () => {
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
      // verify api call
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/error_reports',
        method: 'POST',
        body: {
          error: expect.objectContaining({
            subject: 'Test subject',
            comments: 'Test description',
            user_perceived_severity: 'just_a_comment',
            email: '',
            url: window.location.toString(),
            context_asset_string: window.ENV.context_asset_string,
            user_roles: window.ENV.current_user_roles?.join(','),
          }),
        },
      })
    })

    it('shows success message on successful submission', async () => {
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

    it('shows error message on failed submission', async () => {
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

  describe('reset and cancel tests', () => {
    it('resets the form when cancel is clicked', async () => {
      const {getByTestId} = render(<CreateTicketForm {...props} />)
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      await userEvent.click(getByTestId('cancel-button'))
      expect(getByTestId('subject-input')).toHaveValue('')
      expect(onCancel).toHaveBeenCalled()
    })

    it('exposes resetForm to the parent via ref', () => {
      const ref = createRef<{resetForm: () => void}>()
      const {getByTestId} = render(<CreateTicketForm ref={ref} {...props} />)
      fireEvent.change(getByTestId('subject-input'), {target: {value: 'Test subject'}})
      ref.current?.resetForm()
      expect(getByTestId('subject-input')).toHaveValue('')
    })
  })

  describe('focus management tests', () => {
    it('focuses on the subject field on initial render', () => {
      const {getByTestId} = render(<CreateTicketForm {...props} />)
      const subjectInput = getByTestId('subject-input')
      expect(subjectInput).toHaveFocus()
    })
  })
})

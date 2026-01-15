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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import moment from 'moment-timezone'
import NewAccessToken, {PURPOSE_MAX_LENGTH} from '../NewAccessToken'

const server = setupServer()

describe('NewAccessToken', () => {
  const GENERATE_ACCESS_TOKEN_URI = '/api/v1/users/self/tokens'
  const onClose = vi.fn()
  const onSubmit = vi.fn()

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  afterEach(() => {
    cleanup()
    server.resetHandlers()
  })

  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.TIMEZONE = 'America/Denver'
    window.ENV.FEATURES = window.ENV.FEATURES || {}
    window.ENV.user_is_only_student = false
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

  it('should show an error if the purpose field is too long', async () => {
    const user = userEvent.setup()
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText(/Purpose/)
    purpose.focus()

    await user.paste('a'.repeat(256))
    await user.click(submit)

    const errorText = await screen.findByText(
      `Exceeded the maximum length (${PURPOSE_MAX_LENGTH} characters).`,
    )
    expect(errorText).toBeInTheDocument()
  })

  it('should show an error if the network request fails', async () => {
    const user = userEvent.setup()
    server.use(
      http.post(GENERATE_ACCESS_TOKEN_URI, () => {
        return new HttpResponse(null, {status: 500})
      }),
    )
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText(/Purpose/)

    purpose.focus()
    await user.paste('a'.repeat(20))
    await user.click(submit)

    const errorAlert = await screen.findByRole('alert')
    expect(errorAlert).toHaveTextContent('Generating token failed.')
  })

  it('should be able to submit the form if only the purpose filed is provided', async () => {
    const user = userEvent.setup()
    const token = {purpose: 'Test purpose'}
    const requestBodyCapture = vi.fn()
    server.use(
      http.post(GENERATE_ACCESS_TOKEN_URI, async ({request}) => {
        const body = await request.json()
        requestBodyCapture(body)
        return HttpResponse.json({token})
      }),
    )
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText(/Purpose/)

    // Type the text and wait for it to be fully entered
    await user.clear(purpose)
    purpose.focus()
    await user.paste(token.purpose)
    expect(purpose).toHaveValue(token.purpose)

    await user.click(submit)

    await waitFor(
      () => {
        expect(requestBodyCapture).toHaveBeenCalledWith({token})
        expect(onSubmit).toHaveBeenCalledWith({token})
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
    const requestBodyCapture = vi.fn()
    server.use(
      http.post(GENERATE_ACCESS_TOKEN_URI, async ({request}) => {
        const body = await request.json()
        requestBodyCapture(body)
        return HttpResponse.json({token})
      }),
    )
    render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
    const submit = screen.getByLabelText('Generate Token')
    const purpose = screen.getByLabelText(/Purpose/)
    const expirationDateInput = screen.getByLabelText('Expiration date')
    const expirationTimeInput = screen.getByLabelText('Expiration time')

    // Type the text and wait for it to be fully entered
    await user.clear(purpose)
    purpose.focus()
    await user.paste(token.purpose)
    expect(purpose).toHaveValue(token.purpose)

    expirationDateInput.focus()
    await user.paste(expirationDateValue)
    await user.tab() // blur the date field
    expirationTimeInput.focus()
    await user.paste(expirationTimeValue)
    await user.tab() // blur the time field
    await user.click(submit)

    await waitFor(
      () => {
        expect(requestBodyCapture).toHaveBeenCalledWith({token})
        expect(onSubmit).toHaveBeenCalledWith({token})
      },
      {timeout: 20000}, // Increase timeout for CI
    )
  }, 30000) // Add test timeout

  describe('Feature flag behavior', () => {
    describe('when feature flag is enabled and user is only a student', () => {
      beforeEach(() => {
        window.ENV.FEATURES!.student_access_token_management = true
        window.ENV.user_is_only_student = true
      })

      it('should require an expiration date', async () => {
        const user = userEvent.setup()
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
        const submit = screen.getByLabelText('Generate Token')
        const purpose = screen.getByLabelText(/Purpose/)
        const expirationDateInput = screen.getByLabelText(/Expiration date/)

        // Check that expiration is marked as required
        expect(expirationDateInput).toBeRequired()

        purpose.focus()
        await user.paste('Test purpose')
        await user.click(submit)

        // Should show validation error for missing expiration date
        await waitFor(() => {
          expect(screen.getByText('Expiration date is required.')).toBeInTheDocument()
        })
      })

      it('should show maximum expiration hint message', () => {
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)

        expect(screen.getByText('Maximum expiration is 120 days.')).toBeInTheDocument()
      })

      it('should prevent selecting dates beyond 120 days', async () => {
        const user = userEvent.setup()
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
        const purpose = screen.getByLabelText(/Purpose/)
        const submit = screen.getByLabelText('Generate Token')

        // Try to enter a date that's too far in the future (e.g., 150 days)
        const futureDate = moment.tz(window.ENV.TIMEZONE).add(150, 'days').startOf('day')
        const futureDateString = futureDate.format('MMMM D, YYYY')

        const expirationDateInput = screen.getByLabelText(/Expiration date/)
        const expirationTimeInput = screen.getByLabelText(/Expiration time/)

        purpose.focus()
        await user.paste('Test purpose')
        expirationDateInput.focus()
        await user.paste(futureDateString)
        await user.tab() // blur the date field
        expirationTimeInput.focus()
        await user.paste('12:00 AM')
        await user.tab() // blur the time field
        await user.click(submit)

        await waitFor(() => {
          expect(
            screen.getByText('Expiration date cannot be more than 120 days in the future.'),
          ).toBeInTheDocument()
        })
      })

      it('should accept a valid expiration date within 120 days', async () => {
        const user = userEvent.setup()
        const validDate = moment.tz(window.ENV.TIMEZONE).add(30, 'days').startOf('day')
        const token = {
          purpose: 'Test purpose',
          expires_at: validDate.utc().format('YYYY-MM-DDTHH:mm:ss.SSS[Z]'),
        }
        const validDateString = validDate.format('MMMM D, YYYY')
        const validTimeString = '12:00 AM'

        const requestReceived = vi.fn()
        server.use(
          http.post(GENERATE_ACCESS_TOKEN_URI, () => {
            requestReceived()
            return HttpResponse.json({token})
          }),
        )
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)

        const submit = screen.getByLabelText('Generate Token')
        const purpose = screen.getByLabelText(/Purpose/)
        const expirationDateInput = screen.getByLabelText(/Expiration date/)
        const expirationTimeInput = screen.getByLabelText(/Expiration time/)

        purpose.focus()
        await user.paste(token.purpose)
        expirationDateInput.focus()
        await user.paste(validDateString)
        await user.tab() // blur the date field
        expirationTimeInput.focus()
        await user.paste(validTimeString)
        await user.tab() // blur the time field
        await user.click(submit)

        await waitFor(
          () => {
            expect(requestReceived).toHaveBeenCalled()
          },
          {timeout: 10000},
        )
      })
    })

    describe('when feature flag is disabled or user is not only a student', () => {
      beforeEach(() => {
        window.ENV.FEATURES!.student_access_token_management = false
        window.ENV.user_is_only_student = false
      })

      it('should not require an expiration date', () => {
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
        const expirationDateInput = screen.getByLabelText('Expiration date')

        // Check that expiration is not marked as required
        expect(expirationDateInput).not.toBeRequired()
      })

      it('should show no expiration hint message', () => {
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)

        expect(
          screen.getByText('Leave the expiration fields blank for no expiration.'),
        ).toBeInTheDocument()
      })

      it('should allow submission without expiration date', async () => {
        const user = userEvent.setup()
        const token = {purpose: 'Test purpose'}
        const requestReceived = vi.fn()
        server.use(
          http.post(GENERATE_ACCESS_TOKEN_URI, () => {
            requestReceived()
            return HttpResponse.json({token})
          }),
        )
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)

        const submit = screen.getByLabelText('Generate Token')
        const purpose = screen.getByLabelText(/Purpose/)

        purpose.focus()
        await user.paste(token.purpose)
        await user.click(submit)

        await waitFor(
          () => {
            expect(requestReceived).toHaveBeenCalled()
          },
          {timeout: 10000},
        )
      })
    })

    describe('when user is only a student but feature flag is disabled', () => {
      beforeEach(() => {
        window.ENV.FEATURES!.student_access_token_management = false
        window.ENV.user_is_only_student = true
      })

      it('should not enforce restrictions', () => {
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
        const expirationDateInput = screen.getByLabelText('Expiration date')

        // Should behave like normal user when feature flag is disabled
        expect(expirationDateInput).not.toBeRequired()
        expect(
          screen.getByText('Leave the expiration fields blank for no expiration.'),
        ).toBeInTheDocument()
      })
    })

    describe('when feature flag is enabled but user is not only a student', () => {
      beforeEach(() => {
        window.ENV.FEATURES!.student_access_token_management = true
        window.ENV.user_is_only_student = false
      })

      it('should not enforce restrictions', () => {
        render(<NewAccessToken onSubmit={onSubmit} onClose={onClose} />)
        const expirationDateInput = screen.getByLabelText('Expiration date')

        // Should behave like normal user when user is not only a student
        expect(expirationDateInput).not.toBeRequired()
        expect(
          screen.getByText('Leave the expiration fields blank for no expiration.'),
        ).toBeInTheDocument()
      })
    })
  })
})

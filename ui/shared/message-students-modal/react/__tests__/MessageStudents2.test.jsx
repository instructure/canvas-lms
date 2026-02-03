/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, act, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import MessageStudents from '../index'

const defaultProps = {
  contextCode: 'course_1',
  title: 'Message Students',
  onRequestClose: () => {},
  recipients: [
    {id: '1', displayName: 'John Doe', email: 'john@example.com'},
    {id: '2', displayName: 'Jane Smith', email: 'jane@example.com'},
  ],
}

const server = setupServer(
  http.post('/api/v1/conversations', () => {
    return HttpResponse.json({success: true}, {status: 200})
  }),
)

const renderMessageStudents = (props = {}) => {
  return render(<MessageStudents {...defaultProps} {...props} />)
}

describe('MessageStudents', () => {
  let user

  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => server.resetHandlers())

  beforeEach(() => {
    user = userEvent.setup({delay: null})
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.clearAllTimers()
    vi.useRealTimers()
  })

  describe('form validation', () => {
    it('displays validation error when submitting without subject', async () => {
      renderMessageStudents()
      await act(async () => {
        await user.click(screen.getByTestId('message-students-submit'))
        vi.runAllTimers()
      })
      expect(screen.getByText(/please provide a subject/i)).toBeInTheDocument()
    })
  })

  describe('message submission', () => {
    const fillForm = async () => {
      await act(async () => {
        await user.type(screen.getByLabelText(/subject/i), 'Test Subject')
        await user.type(screen.getByLabelText(/body/i), 'Test Message')
      })
    }

    it('handles server error', async () => {
      server.use(
        http.post('/api/v1/conversations', () => {
          return HttpResponse.json([{attribute: 'subject', message: 'Invalid subject'}], {
            status: 400,
          })
        }),
      )

      renderMessageStudents()
      await fillForm()
      await act(async () => {
        await user.click(screen.getByTestId('message-students-submit'))
        vi.runAllTimers()
      })
      const errorMessage = await screen.findByText('Invalid subject')
      expect(errorMessage).toBeInTheDocument()
    })

    it('calls onRequestClose after successful message send', async () => {
      const onRequestClose = vi.fn()
      renderMessageStudents({onRequestClose})
      await fillForm()
      await act(async () => {
        await user.click(screen.getByTestId('message-students-submit'))
      })
      await screen.findByText('Your message was sent!')
      await act(async () => {
        vi.runAllTimers()
      })
      expect(onRequestClose).toHaveBeenCalled()
    })
  })

  describe('modal behavior', () => {
    it('closes when clicking close button', async () => {
      const onRequestClose = vi.fn()
      renderMessageStudents({onRequestClose})
      await act(async () => {
        await user.click(screen.getByTestId('message-students-cancel'))
        vi.runAllTimers()
      })
      expect(onRequestClose).toHaveBeenCalled()
    })
  })

  describe('recipients display', () => {
    it('shows list of recipients', () => {
      renderMessageStudents()
      expect(screen.getByText('John Doe')).toBeInTheDocument()
      expect(screen.getByText('Jane Smith')).toBeInTheDocument()
    })
  })
})

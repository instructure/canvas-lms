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
import {render, act} from '@testing-library/react'
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
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.clearAllTimers()
    jest.useRealTimers()
  })

  describe('form validation', () => {
    it('displays validation error when submitting without subject', async () => {
      const {getByTestId, getByText} = renderMessageStudents()
      await act(async () => {
        await user.click(getByTestId('message-students-submit'))
        jest.runAllTimers()
      })
      expect(getByText(/please provide a subject/i)).toBeInTheDocument()
    })
  })

  describe('message submission', () => {
    const fillForm = async ({getByLabelText}) => {
      await act(async () => {
        await user.type(getByLabelText(/subject/i), 'Test Subject')
        await user.type(getByLabelText(/body/i), 'Test Message')
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

      const {getByTestId, getByLabelText, findByText} = renderMessageStudents()
      await fillForm({getByLabelText})
      await act(async () => {
        await user.click(getByTestId('message-students-submit'))
        jest.runAllTimers()
      })
      const errorMessage = await findByText('Invalid subject')
      expect(errorMessage).toBeInTheDocument()
    })
  })

  describe('modal behavior', () => {
    it('closes when clicking close button', async () => {
      const onRequestClose = jest.fn()
      const {getByTestId} = renderMessageStudents({onRequestClose})
      await act(async () => {
        await user.click(getByTestId('message-students-cancel'))
        jest.runAllTimers()
      })
      expect(onRequestClose).toHaveBeenCalled()
    })
  })

  describe('recipients display', () => {
    it('shows list of recipients', () => {
      const {getByText} = renderMessageStudents()
      expect(getByText('John Doe')).toBeInTheDocument()
      expect(getByText('Jane Smith')).toBeInTheDocument()
    })
  })
})

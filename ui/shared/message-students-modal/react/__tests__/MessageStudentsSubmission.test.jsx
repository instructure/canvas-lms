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

import {act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {createServer, renderMessageStudents} from './MessageStudentsTestHelpers'

const server = createServer()

describe('MessageStudents message submission', () => {
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

  it('handles server error responses', async () => {
    server.use(
      http.post('/api/v1/conversations', () => {
        return HttpResponse.json([{attribute: 'subject', message: 'Invalid subject'}], {
          status: 400,
        })
      }),
    )

    const {getByTestId, getByLabelText, findByText} = renderMessageStudents()
    await act(async () => {
      await user.type(getByLabelText(/subject/i), 'Test Subject')
      await user.type(getByLabelText(/body/i), 'Test Message')
      await user.click(getByTestId('message-students-submit'))
      vi.runAllTimers()
    })
    const errorMessage = await findByText('Invalid subject')
    expect(errorMessage).toBeInTheDocument()
  })
})

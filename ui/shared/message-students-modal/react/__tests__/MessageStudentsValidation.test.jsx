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
import {createServer, renderMessageStudents} from './MessageStudentsTestHelpers'

const server = createServer()

describe('MessageStudents form validation', () => {
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

  it('displays error when submitting without subject', async () => {
    const {getByTestId, getByText} = renderMessageStudents()
    await act(async () => {
      await user.click(getByTestId('message-students-submit'))
      vi.runAllTimers()
    })
    expect(getByText(/please provide a subject/i)).toBeInTheDocument()
  })

  it('displays error when subject is too long', async () => {
    const {getByLabelText, getByTestId, getByText} = renderMessageStudents()
    const subjectInput = getByLabelText(/subject/i)
    await act(async () => {
      // Use paste instead of type to avoid timeout with 256 characters
      await user.click(subjectInput)
      await user.paste('a'.repeat(256))
      vi.runAllTimers()
    })
    await act(async () => {
      await user.click(getByTestId('message-students-submit'))
      vi.runAllTimers()
    })
    expect(getByText(/subject must contain fewer than 255 characters/i)).toBeInTheDocument()
  })
})

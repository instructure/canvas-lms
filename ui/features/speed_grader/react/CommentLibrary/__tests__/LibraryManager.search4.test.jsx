/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {vi} from 'vitest'
import React from 'react'
import {MockedProvider} from '@apollo/client/testing'
import {act, cleanup, fireEvent, render as rtlRender, waitFor} from '@testing-library/react'
import {createCache} from '@canvas/apollo-v3'
import {commentBankItemMocks} from './mocks'
import LibraryManager from '../LibraryManager'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.useFakeTimers()

const server = setupServer()

describe('LibraryManager - search (part 4)', () => {
  let setFocusToTextAreaMock

  const defaultProps = (props = {}) => {
    return {
      setComment: () => {},
      courseId: '1',
      setFocusToTextArea: setFocusToTextAreaMock,
      userId: '1',
      commentAreaText: '',
      suggestionsRef: document.body,
      ...props,
    }
  }

  beforeAll(() => server.listen())
  afterAll(() => {
    server.close()
    fakeEnv.teardown()
  })

  beforeEach(() => {
    fakeEnv.setup({comment_library_suggestions_enabled: true})
    setFocusToTextAreaMock = vi.fn()
  })

  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
    server.resetHandlers()
    fakeEnv.teardown()
  })

  const render = ({
    props = defaultProps(),
    mocks = commentBankItemMocks({numberOfComments: 10}),
    func = rtlRender,
  } = {}) =>
    func(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <LibraryManager {...props} />
      </MockedProvider>,
    )

  it("fires a request to save the checkbox state when it's clicked", async () => {
    let capturedMethod = null
    let capturedBody = null
    let capturedPath = null
    server.use(
      http.put('/api/v1/users/self/settings', async ({request}) => {
        capturedMethod = request.method
        capturedPath = '/api/v1/users/self/settings'
        capturedBody = await request.json()
        return HttpResponse.json({comment_library_suggestions_enabled: false})
      }),
    )
    const {getByText, getByLabelText} = render()
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    fireEvent.click(getByLabelText('Show suggestions when typing'))

    // Switch to real timers for async operations
    vi.useRealTimers()
    await waitFor(() => {
      expect(capturedMethod).toBe('PUT')
    })

    expect(capturedPath).toBe('/api/v1/users/self/settings')
    expect(capturedBody).toEqual({
      comment_library_suggestions_enabled: false,
    })
    expect(getByLabelText('Show suggestions when typing')).not.toBeChecked()
    expect(ENV.comment_library_suggestions_enabled).toBe(false)

    // Re-enable fake timers for potential cleanup
    vi.useFakeTimers()
  })

  it('does not write to ENV if the request fails', async () => {
    let requestCalled = false
    server.use(
      http.put('/api/v1/users/self/settings', () => {
        requestCalled = true
        return new HttpResponse(null, {status: 500})
      }),
    )
    const {getByText, getByLabelText} = render()
    await act(async () => vi.advanceTimersByTime(1000))
    fireEvent.click(getByText('Open Comment Library'))
    fireEvent.click(getByLabelText('Show suggestions when typing'))

    // Switch to real timers for async operations
    vi.useRealTimers()
    await waitFor(() => {
      expect(requestCalled).toBe(true)
    })

    await waitFor(() => {
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'Error saving suggestion preference',
        type: 'error',
      })
    })

    expect(ENV.comment_library_suggestions_enabled).toBe(true)

    // Re-enable fake timers for potential cleanup
    vi.useFakeTimers()
  })
})

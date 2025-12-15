/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {cleanup, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {type MockedFunction} from 'vitest'
import UncrosslistForm from '../UncrosslistForm'
import {FetchApiError} from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(() => vi.fn()),
}))

const server = setupServer()

describe('UncrosslistForm', () => {
  const defaultProps = {
    courseId: '123',
    sectionId: '456',
    nonxlistCourseId: '789',
    courseName: 'Owning a Dog',
    studentEnrollmentsCount: 5,
  }

  beforeAll(() => server.listen())

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    cleanup()
    server.resetHandlers()
    vi.restoreAllMocks()
  })

  afterAll(() => server.close())

  it('renders the trigger button', () => {
    const {getByTestId} = render(<UncrosslistForm {...defaultProps} />)
    expect(getByTestId('uncrosslist-trigger-button')).toBeInTheDocument()
  })

  it('opens modal when button is clicked', async () => {
    const {getByTestId, getByText} = render(<UncrosslistForm {...defaultProps} />)
    const button = getByTestId('uncrosslist-trigger-button')

    await userEvent.click(button)

    expect(getByText('Are you sure you want to de-cross-list this section?')).toBeInTheDocument()
  })

  it('displays course name when provided', async () => {
    const {getByTestId, getByText} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))

    expect(getByText(/Owning a Dog/)).toBeInTheDocument()
  })

  it('does not display course name section when courseName is empty', async () => {
    const {getByTestId, queryByText} = render(<UncrosslistForm {...defaultProps} courseName="" />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))

    expect(queryByText(/This will move the section back to its original course/)).toBeNull()
  })

  it('displays student enrollment warning when count > 0', async () => {
    const {getByTestId, getByText} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))

    expect(
      getByText(/All grades for students in this course will no longer be visible/),
    ).toBeInTheDocument()
  })

  it('does not display student warning when count is 0', async () => {
    const {getByTestId, queryByText} = render(
      <UncrosslistForm {...defaultProps} studentEnrollmentsCount={0} />,
    )

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))

    expect(
      queryByText(/All grades for students in this course will no longer be visible/),
    ).toBeNull()
  })

  it('closes modal when Cancel button is clicked', async () => {
    const {getByTestId, queryByText} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))
    expect(queryByText('Are you sure you want to de-cross-list this section?')).toBeInTheDocument()

    await userEvent.click(getByTestId('uncrosslist-cancel-button'))

    await waitFor(() => {
      expect(queryByText('Are you sure you want to de-cross-list this section?')).toBeNull()
    })
  })

  it('makes API call on successful submit', async () => {
    let deleteWasCalled = false
    server.use(
      http.delete('/courses/123/sections/456/crosslist', () => {
        deleteWasCalled = true
        return new HttpResponse(null, {status: 200})
      }),
    )

    const {getByTestId} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))
    await userEvent.click(getByTestId('uncrosslist-submit-button'))

    await waitFor(() => {
      expect(deleteWasCalled).toBe(true)
    })
  })

  it('disables buttons while submitting', async () => {
    server.use(
      http.delete('/courses/123/sections/456/crosslist', async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
        return new HttpResponse(null, {status: 200})
      }),
    )

    const {getByTestId} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))
    const submitButton = getByTestId('uncrosslist-submit-button')
    const cancelButton = getByTestId('uncrosslist-cancel-button')

    await userEvent.click(submitButton)

    expect(submitButton).toBeDisabled()
    expect(cancelButton).toBeDisabled()
  })

  it('shows loading text while submitting', async () => {
    server.use(
      http.delete('/courses/123/sections/456/crosslist', async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
        return new HttpResponse(null, {status: 200})
      }),
    )

    const {getByTestId, getByText} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))
    await userEvent.click(getByTestId('uncrosslist-submit-button'))

    expect(getByText('De-Cross-Listing Section...')).toBeInTheDocument()
  })

  it('shows error flash message on API failure', async () => {
    server.use(
      http.delete(
        '/courses/123/sections/456/crosslist',
        () => new HttpResponse(null, {status: 500}),
      ),
    )

    const mockShowFlashError = showFlashError as MockedFunction<typeof showFlashError>
    const mockFlashErrorCall = vi.fn()
    mockShowFlashError.mockReturnValue(mockFlashErrorCall)

    const {getByTestId} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))
    await userEvent.click(getByTestId('uncrosslist-submit-button'))

    await waitFor(() => {
      expect(mockShowFlashError).toHaveBeenCalledWith('Failed to de-cross-list section')
      expect(mockFlashErrorCall).toHaveBeenCalled()
      const errorArg = mockFlashErrorCall.mock.calls[0][0]
      expect(errorArg).toBeInstanceOf(FetchApiError)
      expect(errorArg.message).toContain('500 Internal Server Error')
    })
  })

  it('re-enables buttons after API failure', async () => {
    server.use(
      http.delete(
        '/courses/123/sections/456/crosslist',
        () => new HttpResponse(null, {status: 500}),
      ),
    )

    const {getByTestId} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))
    const submitButton = getByTestId('uncrosslist-submit-button')

    await userEvent.click(submitButton)

    await waitFor(() => {
      expect(submitButton).not.toBeDisabled()
    })
  })

  it('does not close modal while submitting', async () => {
    server.use(
      http.delete('/courses/123/sections/456/crosslist', async () => {
        await new Promise(resolve => setTimeout(resolve, 100))
        return new HttpResponse(null, {status: 200})
      }),
    )

    const {getByTestId, getByText} = render(<UncrosslistForm {...defaultProps} />)

    await userEvent.click(getByTestId('uncrosslist-trigger-button'))
    await userEvent.click(getByTestId('uncrosslist-submit-button'))

    // Modal should still be visible while submitting
    expect(getByText('Are you sure you want to de-cross-list this section?')).toBeInTheDocument()
  })
})

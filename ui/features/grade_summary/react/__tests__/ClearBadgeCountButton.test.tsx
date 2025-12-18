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
import ClearBadgeCountsButton from '../ClearBadgeCountsButton'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {waitFor} from '@testing-library/dom'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(() => vi.fn(() => {})),
  showFlashSuccess: vi.fn(() => vi.fn(() => {})),
}))

const server = setupServer()

describe('ClearBadgeCountsButton', () => {
  const props = {
    userId: '5',
    courseId: '2',
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  it('renders the button with enabled interaction', () => {
    const {getByRole} = render(<ClearBadgeCountsButton {...props} />)
    const button = getByRole('button', {name: 'Clear Badge Counts'})
    expect(button).toBeInTheDocument()
    expect(button).not.toHaveAttribute('disabled')
  })

  it('disables the button and makes API call on click', async () => {
    server.use(
      http.put(`/api/v1/courses/${props.courseId}/submissions/${props.userId}/clear_unread`, () => {
        return new HttpResponse(null, {status: 204})
      }),
    )

    const {getByRole} = render(<ClearBadgeCountsButton {...props} />)
    const button = getByRole('button', {name: 'Clear Badge Counts'})
    await userEvent.click(button)
    expect(button).toBeInTheDocument()
    expect(button).toHaveAttribute('disabled')
  })

  it('shows success message when API call is successful and status is 204', async () => {
    server.use(
      http.put(`/api/v1/courses/${props.courseId}/submissions/${props.userId}/clear_unread`, () => {
        return new HttpResponse(null, {status: 204})
      }),
    )

    const {getByRole} = render(<ClearBadgeCountsButton {...props} />)
    const button = getByRole('button', {name: 'Clear Badge Counts'})
    await userEvent.click(button)
    await waitFor(() => expect(showFlashSuccess).toHaveBeenCalledWith('Badge counts cleared!'))
  })

  it('shows failure message when API call does not return 204', async () => {
    const errorMessage = 'Error clearing badge counts.'
    server.use(
      http.put(`/api/v1/courses/${props.courseId}/submissions/${props.userId}/clear_unread`, () => {
        return new HttpResponse(null, {status: 200})
      }),
    )

    const {getByRole} = render(<ClearBadgeCountsButton {...props} />)
    const button = getByRole('button', {name: 'Clear Badge Counts'})
    await userEvent.click(button)
    await waitFor(() => expect(showFlashError).toHaveBeenCalledWith(errorMessage))
  })

  it('shows error message when API call fails', async () => {
    const errorMessage = 'Error clearing badge counts.'
    server.use(
      http.put(`/api/v1/courses/${props.courseId}/submissions/${props.userId}/clear_unread`, () => {
        return HttpResponse.error()
      }),
    )

    const {getByRole} = render(<ClearBadgeCountsButton {...props} />)
    const button = getByRole('button', {name: 'Clear Badge Counts'})
    await userEvent.click(button)
    await waitFor(() => expect(showFlashError).toHaveBeenCalledWith(errorMessage))
  })
})

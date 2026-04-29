/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {statusColors} from '../../constants/colors'
import {render, within, cleanup} from '@testing-library/react'
import StatusesModal from '../StatusesModal'
import store from '../../stores/index'
import userEvent from '@testing-library/user-event'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer(
  http.get('*', () => new HttpResponse(null, {status: 200})),
  http.post('*', () => new HttpResponse(null, {status: 200})),
  http.put('*', () => new HttpResponse(null, {status: 200})),
  http.delete('*', () => new HttpResponse(null, {status: 200})),
)

describe('Statuses Modal', () => {
  const originalState = store.getState()

  beforeEach(() => {
    server.listen({onUnhandledRequest: 'bypass'})
    fakeENV.setup({
      FEATURES: {
        extended_submission_state: true,
      },
    })
  })

  afterEach(() => {
    cleanup() // Clean up any rendered components
    store.setState(originalState, true)
    server.resetHandlers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  it('renders heading', () => {
    const onClose = vi.fn()
    const afterUpdateStatusColors = vi.fn()

    render(
      <StatusesModal
        onClose={onClose}
        colors={statusColors({})}
        afterUpdateStatusColors={afterUpdateStatusColors}
      />,
    )

    const {getByRole} = within(document.body)
    expect(getByRole('heading', {name: /Statuses/i})).toBeTruthy()
  })

  it('renders six StatusColorListItems', () => {
    const onClose = vi.fn()
    const afterUpdateStatusColors = vi.fn()

    render(
      <StatusesModal
        onClose={onClose}
        colors={statusColors({})}
        afterUpdateStatusColors={afterUpdateStatusColors}
      />,
    )

    const {getAllByRole} = within(document.body)
    expect(getAllByRole('listitem')).toHaveLength(6)
  })

  it('onClose is called when closed', async () => {
    const onClose = vi.fn()
    const afterUpdateStatusColors = vi.fn()

    const {getByRole} = render(
      <StatusesModal
        onClose={onClose}
        colors={statusColors({})}
        afterUpdateStatusColors={afterUpdateStatusColors}
      />,
    )

    // Find the close button by its text content
    const closeButton = getByRole('button', {name: /Done/i})
    expect(closeButton).toBeInTheDocument()

    // Click the button and verify onClose was called
    await userEvent.click(closeButton)
    expect(onClose).toHaveBeenCalledTimes(1)
  })
})

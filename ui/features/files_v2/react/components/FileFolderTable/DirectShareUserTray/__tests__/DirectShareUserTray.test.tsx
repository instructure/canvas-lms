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
import {render, cleanup, screen, waitFor} from '@testing-library/react'
import DirectShareUserTray from '../DirectShareUserTray'
import useContentShareUserSearchApi from '@canvas/direct-sharing/react/effects/useContentShareUserSearchApi'
import userEvent from '@testing-library/user-event'
import {FAKE_FILES} from '../../../../../fixtures/fakeData'
import {RowsProvider} from '../../../../contexts/RowsContext'
import {mockRowsContext} from '../../__tests__/testUtils'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

vi.mock('@canvas/direct-sharing/react/effects/useContentShareUserSearchApi')

const server = setupServer()

let capturedRequest: {path: string; body: any} | null = null

const userA = {
  id: '1',
  name: 'Jack Dawson',
  short_name: 'Jack',
  sortable_name: 'Dawson, Jack',
  avatar_url: '',
  email: '',
  created_at: '',
}

const userB = {
  id: '2',
  name: 'Rose DeWitt Bukater',
  short_name: 'Rose',
  sortable_name: 'DeWitt Bukater, Rose',
  avatar_url: '',
  email: '',
  created_at: '',
}

const defaultProps = {
  open: true,
  courseId: '1',
  onDismiss: vi.fn(),
  file: FAKE_FILES[0],
}

const renderComponent = (props?: any) =>
  render(
    <RowsProvider value={mockRowsContext}>
      <DirectShareUserTray {...defaultProps} {...props} />
    </RowsProvider>,
  )

describe('DirectShareUserTray', () => {
  let ariaLive: HTMLElement

  beforeAll(() => {
    server.listen()
    ;(window as any).ENV = {COURSE_ID: '42'}
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    server.close()
    delete (window as any).ENV
    if (ariaLive) document.body.removeChild(ariaLive)
  })

  beforeEach(() => {
    capturedRequest = null
    ;(useContentShareUserSearchApi as any).mockImplementationOnce(({success}: {success: any}) => {
      success([userA, userB])
    })
    server.use(
      http.post('/api/v1/users/self/content_shares', async ({request}) => {
        capturedRequest = {
          path: new URL(request.url).pathname,
          body: await request.json(),
        }
        return HttpResponse.json({})
      }),
    )
  })

  afterEach(async () => {
    server.resetHandlers()
    vi.clearAllMocks()
    vi.resetAllMocks()
    cleanup()
  })

  it('renders', () => {
    renderComponent()
    expect(screen.getByText(/send to.../i)).toBeInTheDocument()
    expect(screen.getByText(/select at least one person/i)).toBeInTheDocument()
    expect(screen.getByTestId('direct-share-user-cancel')).toBeInTheDocument()
    expect(screen.getByTestId('direct-share-user-send')).toBeInTheDocument()
  })

  it('shows an error message after trying to submit with an blank selector', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('direct-share-user-send'))
    expect(screen.getByText(/at least one person should be selected/i)).toBeInTheDocument()
  })

  describe('shows an alert message', () => {
    it('when fetch is made successfully', async () => {
      renderComponent()

      const input = await screen.findByLabelText(/select at least one person/i)
      await userEvent.click(input)
      await userEvent.type(input, userA.name)
      await waitFor(() => {
        expect(screen.queryByText(userA.name)).toBeInTheDocument()
      })
      await userEvent.click(screen.getByText(userA.name))
      await userEvent.click(screen.getByTestId('direct-share-user-send'))

      expect(capturedRequest).not.toBeNull()
      expect(capturedRequest?.path).toBe('/api/v1/users/self/content_shares')
      expect(capturedRequest?.body).toEqual({
        receiver_ids: ['1'],
        content_type: 'attachment',
        content_id: '178',
      })

      expect(screen.getAllByText(/start/i)[0]).toBeInTheDocument()
      expect(screen.getAllByText(/success/i)[0]).toBeInTheDocument()
      expect(defaultProps.onDismiss).toHaveBeenCalled()
    })

    it('when fetch fails', async () => {
      server.use(
        http.post('/api/v1/users/self/content_shares', async ({request}) => {
          capturedRequest = {
            path: new URL(request.url).pathname,
            body: await request.json(),
          }
          return new HttpResponse(null, {status: 500})
        }),
      )

      renderComponent()

      const input = await screen.findByLabelText(/select at least one person/i)
      await userEvent.click(input)
      await userEvent.type(input, userA.name)
      await waitFor(() => {
        expect(screen.queryByText(userA.name)).toBeInTheDocument()
      })
      await userEvent.click(screen.getByText(userA.name))
      await userEvent.click(screen.getByTestId('direct-share-user-send'))

      expect(capturedRequest).not.toBeNull()
      expect(capturedRequest?.path).toBe('/api/v1/users/self/content_shares')
      expect(capturedRequest?.body).toEqual({
        receiver_ids: ['1'],
        content_type: 'attachment',
        content_id: '178',
      })

      expect(screen.getAllByText(/start/i)[0]).toBeInTheDocument()
      expect(screen.getAllByText(/error/i)[0]).toBeInTheDocument()
      expect(defaultProps.onDismiss).not.toHaveBeenCalled()
    })
  })
})

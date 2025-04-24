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
import doFetchApi from '@canvas/do-fetch-api-effect'
import userEvent from '@testing-library/user-event'
import {FAKE_FILES} from '../../../../../fixtures/fakeData'

jest.mock('@canvas/direct-sharing/react/effects/useContentShareUserSearchApi')
jest.mock('@canvas/do-fetch-api-effect')

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
  onDismiss: jest.fn(),
  file: FAKE_FILES[0],
}

const renderComponent = (props?: any) =>
  render(<DirectShareUserTray {...defaultProps} {...props} />)

describe('DirectShareUserTray', () => {
  let ariaLive: HTMLElement

  beforeAll(() => {
    // @ts-expect-error
    window.ENV = {COURSE_ID: '42'}
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    // @ts-expect-error
    delete window.ENV
    if (ariaLive) document.body.removeChild(ariaLive)
  })

  beforeEach(() => {
    ;(useContentShareUserSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([userA, userB])
    })
    ;(doFetchApi as jest.Mock).mockResolvedValue({})
  })

  afterEach(async () => {
    jest.clearAllMocks()
    jest.resetAllMocks()
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

      expect(doFetchApi as jest.Mock).toHaveBeenCalledWith({
        method: 'POST',
        path: '/api/v1/users/self/content_shares',
        body: {
          receiver_ids: ['1'],
          content_type: 'attachment',
          content_id: 178,
        },
      })

      expect(await screen.getAllByText(/start/i)[0]).toBeInTheDocument()
      expect(await screen.getAllByText(/success/i)[0]).toBeInTheDocument()
      expect(defaultProps.onDismiss).toHaveBeenCalled()
    })

    it('when fetch fails', async () => {
      ;(doFetchApi as jest.Mock).mockRejectedValueOnce(() => ({}))

      renderComponent()

      const input = await screen.findByLabelText(/select at least one person/i)
      await userEvent.click(input)
      await userEvent.type(input, userA.name)
      await waitFor(() => {
        expect(screen.queryByText(userA.name)).toBeInTheDocument()
      })
      await userEvent.click(screen.getByText(userA.name))
      await userEvent.click(screen.getByTestId('direct-share-user-send'))

      expect(doFetchApi as jest.Mock).toHaveBeenCalledWith({
        method: 'POST',
        path: '/api/v1/users/self/content_shares',
        body: {
          receiver_ids: ['1'],
          content_type: 'attachment',
          content_id: 178,
        },
      })

      expect(await screen.getAllByText(/start/i)[0]).toBeInTheDocument()
      expect(await screen.getAllByText(/error/i)[0]).toBeInTheDocument()
      expect(defaultProps.onDismiss).not.toHaveBeenCalled()
    })
  })
})

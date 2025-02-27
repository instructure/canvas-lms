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
import {render, fireEvent, act, screen} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import DirectShareUserTray from '../DirectShareUserTray'
import {enableFetchMocks} from 'jest-fetch-mock'
import useContentShareUserSearchApi from '@canvas/direct-sharing/react/effects/useContentShareUserSearchApi'
import {FAKE_FILES} from '../../../../../fixtures/fakeData'

enableFetchMocks()

jest.mock('@canvas/direct-sharing/react/effects/useContentShareUserSearchApi')

const flushAllTimersAndPromises = async () => {
  while (jest.getTimerCount() > 0) {
    await act(async () => {
      jest.runAllTimers()
    })
  }
}

async function selectUser(name = 'abc') {
  fireEvent.change(await screen.findByLabelText(/select at least one person/i), {
    target: {value: name},
  })
  await act(async () => {
    jest.runAllTimers()
  }) // let the debounce happen
  await fireEvent.click(screen.getByText(name))
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
    if (ariaLive) ariaLive.remove()
  })

  beforeEach(() => {
    jest.useFakeTimers()
    ;(useContentShareUserSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
  })

  afterEach(async () => {
    await flushAllTimersAndPromises()
    fetchMock.restore()
  })

  it('renders', () => {
    renderComponent()
    expect(screen.getByText(/send to.../i)).toBeInTheDocument()
    expect(screen.getByText(/select at least one person/i)).toBeInTheDocument()
    expect(screen.getByText(/cancel/i)).toBeInTheDocument()
    expect(screen.getByText('Send')).toBeInTheDocument()
  })

  it('shows an error message after trying to submit with an blank selector', async () => {
    renderComponent()
    fireEvent.click(screen.getByText('Send'))
    expect(screen.getByText(/at least one person should be selected/i)).toBeInTheDocument()
  })

  describe('shows an alert message', () => {
    it('when fetch is made successfully', async () => {
      fetchMock.postOnce('path:/api/v1/users/self/content_shares', 200)
      renderComponent()
      await selectUser()
      fireEvent.click(screen.getByText('Send'))
      const mockCall = fetchMock.lastCall()
      const fetchOptions = mockCall?.[1] || {}
      expect(fetchOptions.method).toBe('POST')
      expect(JSON.parse(fetchOptions.body?.toString() || '')).toMatchObject({
        receiver_ids: ['abc'],
        content_type: 'attachment',
        content_id: '178',
      })
      await act(() => {
        fetchMock.flush(true)
      })
      expect(screen.getAllByText(/success/i)).toHaveLength(2) // visible and sr alert
      expect(defaultProps.onDismiss).toHaveBeenCalled()
    })

    it('when fetch fails', async () => {
      fetchMock.postOnce('path:/api/v1/users/self/content_shares', 400)
      const {getByText, getAllByText} = renderComponent()
      await selectUser()
      fireEvent.click(getByText('Send'))
      await act(() => {
        fetchMock.flush(true)
      })
      expect(getAllByText(/error/i)).toHaveLength(2) // visible and sr alert
      expect(defaultProps.onDismiss).toHaveBeenCalled()
    })
  })
})

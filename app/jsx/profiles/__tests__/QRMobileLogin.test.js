/* Copyright (C) 2020 - present Instructure, Inc.
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
import MockDate from 'mockdate'
import fetchMock from 'fetch-mock'
import moment from 'moment'
import {render, act} from '@testing-library/react'
import {QRMobileLogin} from '../QRMobileLogin'

// a fake QR code image, and then a another one after generating a new code
const loginImageJsons = [
  {png: 'R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='},
  {png: 'R0lGODlhAQABZZZZZCH5BAEKAAEALZZZZZABAAEAAAICTAEAOn=='}
]

const route = '/canvas/login.png'

// used for when we want fetchMock not to ever respond
const doNotRespond = Function.prototype

describe('QRMobileLogin', () => {
  describe('before the API call responds', () => {
    beforeEach(() => {
      fetchMock.post(route, doNotRespond, {overwriteRoutes: true})
    })

    afterEach(() => fetchMock.restore())

    it('renders component', () => {
      const {getByText} = render(<QRMobileLogin />)
      expect(getByText(/QR for Mobile Login/)).toBeVisible()
      expect(getByText(/To log in to your Canvas account/)).toBeVisible()
    })

    it('renders a spinner while fetching QR image', () => {
      const {getByTestId} = render(<QRMobileLogin />)
      expect(getByTestId('qr-code-spinner')).toBeInTheDocument()
    })
  })

  describe('after the API call responds', () => {
    beforeEach(() => {
      jest.useFakeTimers()
      fetchMock
        .postOnce(route, loginImageJsons[0], {overwriteRoutes: true})
        .postOnce(route, loginImageJsons[1], {overwriteRoutes: false})
    })

    afterEach(() => {
      fetchMock.restore()
      MockDate.reset()
    })

    // advances both global time and the jest timers by the given time duration
    function advance(...args) {
      const delay = moment.duration(...args).asMilliseconds()
      act(() => {
        const now = Date.now()
        MockDate.set(now + delay)
        jest.advanceTimersByTime(delay)
      })
    }

    it('renders the image in the response, and the right expiration time', async () => {
      const {findByTestId, getByText} = render(<QRMobileLogin onDismiss={Function.prototype} />)
      const image = await findByTestId('qr-code-image')
      expect(image.src).toBe(`data:image/png;base64, ${loginImageJsons[0].png}`)
      expect(getByText(/expires in 10 minutes/i)).toBeInTheDocument()
    })

    it('updates the expiration as time elapses', async () => {
      const {findByText} = render(<QRMobileLogin />)
      await findByText(/expires in 10 minutes/i)
      advance(1, 'minute')
      const expiresIn = await findByText(/expires in 9 minutes/i)
      expect(expiresIn).toBeInTheDocument()
    })

    it('shows the right thing when the token has expired', async () => {
      const refreshInterval = moment.duration(15, 'minutes')
      const pollInterval = moment.duration(3, 'minutes')
      const {findByText} = render(
        <QRMobileLogin refreshInterval={refreshInterval} pollInterval={pollInterval} />
      )
      await findByText(/expires in 10 minutes/)
      advance(11, 'minutes') // code is only good for 10
      const expiresIn = await findByText(/code has expired/i)
      expect(expiresIn).toBeInTheDocument()
    })

    it('refreshes the code at the right time', async () => {
      const refreshInterval = moment.duration(2, 'minutes')
      const {findByText, findByTestId} = render(<QRMobileLogin refreshInterval={refreshInterval} />)
      const image = await findByTestId('qr-code-image')
      expect(image.src).toBe(`data:image/png;base64, ${loginImageJsons[0].png}`)
      expect(fetchMock.calls(route)).toHaveLength(1)
      advance(1, 'minute')
      await findByText(/expires in 9 minutes/)
      advance(1, 'minute')
      await findByText(/expires in 10 minutes/)
      expect(fetchMock.calls(route)).toHaveLength(2)
      expect(image.src).toBe(`data:image/png;base64, ${loginImageJsons[1].png}`)
    })
  })
})

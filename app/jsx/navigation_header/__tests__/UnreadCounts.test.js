// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
import React from 'react'
import {render} from '@testing-library/react'
import {findByText} from '@testing-library/dom'
import UnreadCounts from '../UnreadCounts'

const onUpdate = jest.fn(Function.prototype)
const apiStem = 'admin/users'
const userId = 5
const unreadCountFromApi = 10
const pollInterval = 60000
const allowedAge = 30000
const maxTries = 5
const storageKey = `unread_count_${userId}_${apiStem.replace(/\//g, '_')}`

const props = {
  onUpdate,
  dataUrl: `http://getdata.edu/api/v1/${apiStem}/unread_count`,
  pollIntervalMs: pollInterval,
  allowedAge,
  maxTries
}

expect.extend({
  toBeNotLongAfter(received, time, tolerance = 500) {
    const pass = received - time < tolerance
    return {pass}
  }
})

describe('GlobalNavigation::UnreadCounts', () => {
  beforeEach(() => {
    const span = document.createElement('span')
    span.id = 'target-span'
    document.body.appendChild(span)
    fetch.resetMocks()
    onUpdate.mockClear()
    window.ENV.current_user_id = userId
  })

  describe('session storage', () => {
    let fetchMock
    let target

    beforeEach(() => {
      fetchMock = fetch.mockResponse(JSON.stringify({unread_count: unreadCountFromApi}))
      target = document.getElementById('target-span')
      window.sessionStorage.removeItem(storageKey)
      jest.useFakeTimers()
    })

    it('when no stored value, uses and stores the value fetched', async () => {
      const start = new Date()
      render(<UnreadCounts {...props} targetEl={target} />)
      jest.runAllTimers()
      expect(await findByText(target, `${unreadCountFromApi} unread.`)).toBeInTheDocument()
      expect(fetchMock).toHaveBeenCalled()
      const saved = JSON.parse(window.sessionStorage.getItem(storageKey))
      expect(saved.unreadCount).toBe(unreadCountFromApi)
      expect(saved.updatedAt).toBeNotLongAfter(start)
    })

    it('uses stored value when it is new enough', async () => {
      const last = {
        updatedAt: +new Date() - allowedAge / 2, // within the allowed age
        unreadCount: 12
      }
      window.sessionStorage.setItem(storageKey, JSON.stringify(last))
      render(<UnreadCounts {...props} targetEl={target} />)
      expect(await findByText(target, '12 unread.')).toBeInTheDocument()
      expect(fetchMock).not.toHaveBeenCalled()
    })

    it('fetches value when stored value is too old', async () => {
      const last = {
        updatedAt: +new Date() - allowedAge * 10, // way past the allowed age
        unreadCount: 12
      }
      window.sessionStorage.setItem(storageKey, JSON.stringify(last))
      render(<UnreadCounts {...props} targetEl={target} />)
      jest.runAllTimers()
      expect(await findByText(target, `${unreadCountFromApi} unread.`)).toBeInTheDocument()
      expect(fetchMock).toHaveBeenCalled()
    })

    it('delays fetching until the allowed age has expired', () => {
      const age = allowedAge / 2 // within the allowed age
      const last = {
        updatedAt: +new Date() - age,
        unreadCount: 12
      }
      window.sessionStorage.setItem(storageKey, JSON.stringify(last))
      render(<UnreadCounts {...props} targetEl={target} />)
      expect(fetchMock).not.toHaveBeenCalled()
      jest.advanceTimersByTime(allowedAge - age + 50) // just past the allowed age
      expect(fetchMock).toHaveBeenCalled()
    })
  })

  describe('API sad path', () => {
    let fetchMock
    let target

    beforeEach(() => {
      fetchMock = fetch.mockReject(new Error('womp womp'))
      target = document.getElementById('target-span')
      window.sessionStorage.removeItem(storageKey)
      jest.useFakeTimers()
    })

    it('calls the error callback and retries the right number of times', done => {
      let errors = 0
      function onError() {
        errors += 1
        expect(errors).toBeGreaterThan(0)
        jest.advanceTimersByTime(pollInterval * maxTries)
        if (errors >= maxTries) {
          expect(fetchMock).toHaveBeenCalledTimes(maxTries)
          done()
        }
      }
      render(<UnreadCounts {...props} targetEl={target} onError={onError} />)
    })
  })
})

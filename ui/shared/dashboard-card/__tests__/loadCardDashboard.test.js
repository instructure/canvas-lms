/* eslint-disable promise/no-callback-in-promise */
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

import moxios from 'moxios'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {CardDashboardLoader, resetCardCache} from '../loadCardDashboard'

jest.mock('@canvas/alerts/react/FlashAlert')

describe('loadCardDashboard', () => {
  let cardDashboardLoader
  beforeEach(() => {
    moxios.install()
    cardDashboardLoader = new CardDashboardLoader()
    // Clear any cached data from previous tests
    resetCardCache()
    // Clear session storage to prevent cached data from affecting tests
    sessionStorage.clear()
    // Mock sessionStorage.getItem to return null to prevent cached data
    jest.spyOn(Storage.prototype, 'getItem').mockReturnValue(null)
  })

  afterEach(() => {
    moxios.uninstall()
    resetCardCache()
    jest.restoreAllMocks()
  })

  describe('with observer', () => {
    it('loads student cards asynchronously and calls back renderFn', done => {
      // Mock Promise.race to ensure it always waits for the XHR promise
      const originalRace = Promise.race
      Promise.race = jest.fn().mockImplementation(promises => promises[0])

      const callback = jest.fn()
      cardDashboardLoader.loadCardDashboard(callback, 2)

      // Use setTimeout to ensure we're checking after the initial Promise.race resolution
      setTimeout(() => {
        moxios.wait(() => {
          moxios.requests
            .mostRecent()
            .respondWith({
              status: 200,
              response: ['card'],
            })
            .then(() => {
              expect(callback).toHaveBeenCalledWith(['card'], true)
              // Restore Promise.race
              Promise.race = originalRace
              done()
            })
            .catch(e => {
              Promise.race = originalRace
              done.fail(e)
            })
        })
      }, 0)
    })

    it('saves student cards and calls back renderFn immediately if requested again', done => {
      const callback = jest.fn()
      cardDashboardLoader.loadCardDashboard(callback, 5)
      moxios.wait(() => {
        moxios.requests
          .mostRecent()
          .respondWith({
            status: 200,
            response: ['card'],
          })
          .then(() => {
            resetCardCache()
            cardDashboardLoader.loadCardDashboard(callback, 5)
            moxios.wait(() => {
              expect(callback).toHaveBeenCalledWith(['card'], true)
              expect(moxios.requests.count()).toBe(1)
              done()
            })
          })
          .catch(e => {
            throw e
          })
      })
    })

    it('fails gracefully', done => {
      const callback = jest.fn()
      cardDashboardLoader.loadCardDashboard(callback, 2)
      moxios.wait(() => {
        moxios.requests
          .mostRecent()
          .respondWith({
            status: 500,
          })
          .then(() => {
            expect(showFlashAlert).toHaveBeenCalledTimes(1)
            done()
          })
      })
    })
  })
})

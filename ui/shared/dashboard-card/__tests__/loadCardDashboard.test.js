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

import {http, HttpResponse} from 'msw'
import {mswServer} from '../../msw/mswServer'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {CardDashboardLoader, resetCardCache} from '../loadCardDashboard'

jest.mock('@canvas/alerts/react/FlashAlert')

const server = mswServer([])

describe('loadCardDashboard', () => {
  let cardDashboardLoader

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    cardDashboardLoader = new CardDashboardLoader()
    // Clear any cached data from previous tests
    resetCardCache()
    // Clear session storage to prevent cached data from affecting tests
    sessionStorage.clear()
    // Mock sessionStorage.getItem to return null to prevent cached data
    jest.spyOn(Storage.prototype, 'getItem').mockReturnValue(null)
  })

  afterEach(() => {
    server.resetHandlers()
    resetCardCache()
    jest.restoreAllMocks()
  })

  afterAll(() => {
    server.close()
  })

  describe('with observer', () => {
    it('loads student cards asynchronously and calls back renderFn', async () => {
      server.use(
        http.get('*/api/v1/dashboard/dashboard_cards', ({request}) => {
          const url = new URL(request.url)
          expect(url.searchParams.get('observed_user_id')).toBe('2')
          return new HttpResponse(JSON.stringify(['card']), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const callback = jest.fn()

      // The CardDashboardLoader uses a timeout to debounce calls
      cardDashboardLoader.loadCardDashboard(callback, 2)

      // Wait for the async operations to complete
      await new Promise(resolve => setTimeout(resolve, 100))

      expect(callback).toHaveBeenCalledWith(['card'], true)
    })

    it('saves student cards and calls back renderFn immediately if requested again', async () => {
      let requestCount = 0
      server.use(
        http.get('*/api/v1/dashboard/dashboard_cards', () => {
          requestCount++
          return new HttpResponse(JSON.stringify(['card']), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const callback = jest.fn()
      cardDashboardLoader.loadCardDashboard(callback, 5)

      // Wait for first load
      await new Promise(resolve => setTimeout(resolve, 100))

      // Reset and load again
      resetCardCache()
      cardDashboardLoader.loadCardDashboard(callback, 5)

      // Wait for second load
      await new Promise(resolve => setTimeout(resolve, 100))

      expect(callback).toHaveBeenCalledWith(['card'], true)
      expect(requestCount).toBe(1) // Should only make one request due to caching
    })

    it('fails gracefully', async () => {
      server.use(
        http.get('*/api/v1/dashboard/dashboard_cards', () => {
          return new HttpResponse(null, {
            status: 500,
          })
        }),
      )

      const callback = jest.fn()
      cardDashboardLoader.loadCardDashboard(callback, 2)

      // Wait for the async operations to complete
      await new Promise(resolve => setTimeout(resolve, 100))

      expect(showFlashAlert).toHaveBeenCalledTimes(1)
    })
  })
})

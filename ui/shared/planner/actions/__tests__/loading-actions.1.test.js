/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {mswServer} from '../../../msw/mswServer'
import moment from 'moment-timezone'
import * as Actions from '../loading-actions'
import {initialize as alertInitialize} from '../../utilities/alertUtils'

jest.mock('../../utilities/apiUtils', () => ({
  ...jest.requireActual('../../utilities/apiUtils'),
  getContextCodesFromState: jest.requireActual('../../utilities/apiUtils').getContextCodesFromState,
  findNextLink: jest.fn(),
  transformApiToInternalItem: jest.fn(response => ({
    ...response,
    newActivity: response.new_activity,
    transformedToInternal: true,
  })),
  transformInternalToApiItem: jest.fn(internal => ({...internal, transformedToApi: true})),
  observedUserId: jest.requireActual('../../utilities/apiUtils').observedUserId,
}))

const getBasicState = () => ({
  courses: [],
  groups: [],
  timeZone: 'UTC',
  days: [
    ['2017-05-22', [{id: '42', dateBucketMoment: moment.tz('2017-05-22', 'UTC')}]],
    ['2017-05-24', [{id: '42', dateBucketMoment: moment.tz('2017-05-24', 'UTC')}]],
  ],
  loading: {
    futureNextUrl: null,
    pastNextUrl: null,
  },
  weeklyDashboard: {
    // copied from weekly-reducers INITIAL_OPTIONS
    weekStart: moment.tz('UTC').startOf('week'),
    weekEnd: moment.tz('UTC').endOf('week'),
    thisWeek: moment.tz('UTC').startOf('week'),
    weeks: {},
  },
  selectedObservee: null,
  currentUser: {id: '1'},
})

const server = mswServer([])

describe('api actions', () => {
  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    expect.hasAssertions()
    alertInitialize({
      visualSuccessCallback() {},
      visualErrorCallback() {},
      srAlertCallback() {},
    })
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  describe('sendFetchRequest', () => {
    it('fetches from the specified moment if there is no next url in the loadingOptions', async () => {
      const fromMoment = moment.tz('Asia/Tokyo')
      let capturedUrl
      server.use(
        http.get('*', ({request}) => {
          capturedUrl = request.url
          return new HttpResponse(JSON.stringify([]), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      await Actions.sendFetchRequest({
        fromMoment,
        getState: () => ({loading: {}}),
      })

      const url = new URL(capturedUrl)
      expect(url.pathname + url.search).toBe(
        `/api/v1/planner/items?start_date=${encodeURIComponent(fromMoment.toISOString())}`,
      )
    })

    it('fetches using futureNextUrl if specified', async () => {
      const fromMoment = moment.tz('Asia/Tokyo')
      let capturedUrl
      server.use(
        http.get('*', ({request}) => {
          capturedUrl = request.url
          return new HttpResponse(JSON.stringify([]), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      await Actions.sendFetchRequest({
        fromMoment,
        getState: () => ({loading: {futureNextUrl: '/next/url'}}),
      })

      const url = new URL(capturedUrl)
      expect(url.pathname).toBe('/next/url')
    })

    it('sends past parameters if loading into the past', async () => {
      const fromMoment = moment.tz('Asia/Tokyo')
      let capturedUrl
      server.use(
        http.get('*', ({request}) => {
          capturedUrl = request.url
          return new HttpResponse(JSON.stringify([]), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      await Actions.sendFetchRequest({
        fromMoment,
        mode: 'past',
        getState: () => ({loading: {}}),
      })

      const url = new URL(capturedUrl)
      expect(url.pathname + url.search).toBe(
        `/api/v1/planner/items?end_date=${encodeURIComponent(fromMoment.toISOString())}&order=desc`,
      )
    })

    it('sends pastNextUrl if loading into the past', async () => {
      const fromMoment = moment.tz('Asia/Tokyo')
      let capturedUrl
      server.use(
        http.get('*', ({request}) => {
          capturedUrl = request.url
          return new HttpResponse(JSON.stringify([]), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      await Actions.sendFetchRequest({
        fromMoment,
        mode: 'past',
        getState: () => ({loading: {pastNextUrl: '/past/next/url'}}),
      })

      const url = new URL(capturedUrl)
      expect(url.pathname).toBe('/past/next/url')
    })

    it('transforms the results', async () => {
      const fromMoment = moment.tz('Asia/Tokyo')
      server.use(
        http.get('*', () => {
          return new HttpResponse(JSON.stringify([{some: 'items'}]), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const result = await Actions.sendFetchRequest({fromMoment, getState: () => ({loading: {}})})
      expect(result).toEqual({
        response: expect.anything(),
        transformedItems: [{some: 'items', transformedToInternal: true}],
      })
    })
  })

  describe('getPlannerItems', () => {
    it('dispatches START_LOADING_ITEMS, getFirstNewActivityDate, and starts the saga', async () => {
      const mockDispatch = jest.fn(() => Promise.resolve({data: []}))
      const mockMoment = moment()
      server.use(
        http.get('*', () => {
          return new HttpResponse(JSON.stringify([{dateBucketMoment: mockMoment}]), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      await Actions.getPlannerItems(moment('2017-12-18'))(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingItems())
      expect(mockDispatch).toHaveBeenCalledWith(Actions.continueLoadingInitialItems())
      expect(mockDispatch).toHaveBeenCalledWith(Actions.peekIntoPastSaga())
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingFutureSaga())
      const getFirstNewActivityDateThunk = mockDispatch.mock.calls[4][0]
      expect(typeof getFirstNewActivityDateThunk).toBe('function')

      await getFirstNewActivityDateThunk(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'FOUND_FIRST_NEW_ACTIVITY_DATE',
        }),
      )
    })
  })

  describe('getFirstNewActivityDate', () => {
    it('sends deep past, filter, and order parameters', async () => {
      const mockDispatch = jest.fn(() => Promise.resolve({data: []}))
      const mockMoment = moment.tz('Asia/Tokyo').startOf('day')
      let capturedUrl
      server.use(
        http.get('*/planner/items', ({request}) => {
          capturedUrl = request.url
          return new HttpResponse(JSON.stringify({data: []}), {
            status: 200,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      await Actions.getFirstNewActivityDate(mockMoment)(mockDispatch, getBasicState)

      const url = new URL(capturedUrl)
      expect(url.pathname + url.search).toBe(
        `/api/v1/planner/items?start_date=${encodeURIComponent(
          mockMoment.subtract(6, 'months').toISOString(),
        )}&filter=new_activity&order=asc`,
      )
    })

    it('calls the alert method when it fails to get new activity', async () => {
      const fakeAlert = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })
      const mockDispatch = jest.fn()
      const mockMoment = moment.tz('Asia/Tokyo').startOf('day')
      server.use(
        http.get('*/planner/items', () => {
          return new HttpResponse(JSON.stringify({some: 'response data'}), {
            status: 500,
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      await Actions.getFirstNewActivityDate(mockMoment)(mockDispatch, getBasicState)
      expect(fakeAlert).toHaveBeenCalled()
    })
  })

  describe('loadFutureItems', () => {
    it('dispatches GETTING_FUTURE_ITEMS and starts the saga', () => {
      const mockDispatch = jest.fn()
      Actions.loadFutureItems()(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith(
        Actions.gettingFutureItems({loadMoreButtonClicked: false}),
      )
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingFutureSaga())
    })

    it('dispatches nothing if allFutureItemsLoaded', () => {
      const mockDispatch = jest.fn()
      const state = getBasicState()
      state.loading.allFutureItemsLoaded = true
      Actions.loadFutureItems()(mockDispatch, () => state)
      expect(mockDispatch).not.toHaveBeenCalled()
    })
  })

  describe('scrollIntoPast', () => {
    it('dispatches GETTING_PAST_ITEMS and starts the saga', () => {
      const mockDispatch = jest.fn()
      Actions.scrollIntoPast()(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith(Actions.scrollIntoPastAction())
      expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingPastItems())
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingPastSaga())
    })

    it('dispatches nothing if allPastItemsLoaded', () => {
      const mockDispatch = jest.fn()
      const state = getBasicState()
      state.loading.allPastItemsLoaded = true
      Actions.scrollIntoPast()(mockDispatch, () => state)
      expect(mockDispatch).not.toHaveBeenCalled()
    })
  })

  describe('loadPastButtonClicked', () => {
    it('dispatches GETTING_PAST_ITEMS without the scroll into past action', () => {
      const mockDispatch = jest.fn()
      Actions.loadPastButtonClicked()(mockDispatch, getBasicState)
      expect(mockDispatch).not.toHaveBeenCalledWith(Actions.scrollIntoPastAction())
      expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingPastItems())
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingPastSaga())
    })
  })

  describe('loadPastUntilNewActivity', () => {
    it('dispatches getting past items and starts the saga', () => {
      const mockDispatch = jest.fn()
      Actions.loadPastUntilNewActivity()(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith(
        Actions.gettingPastItems({
          seekingNewActivity: true,
        }),
      )
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingPastUntilNewActivitySaga())
    })
  })
})

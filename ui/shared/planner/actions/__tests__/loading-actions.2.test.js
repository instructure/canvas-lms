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
import {setupServer} from 'msw/node'
import moment from 'moment-timezone'
import MockDate from 'mockdate'
import * as Actions from '../loading-actions'
import {initialize as alertInitialize} from '../../utilities/alertUtils'
import configureStore from '../../store/configureStore'

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

const server = setupServer()

describe('api actions', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    expect.hasAssertions()
    alertInitialize({
      visualSuccessCallback() {},
      visualErrorCallback() {},
      srAlertCallback() {},
    })
  })
  describe('weekly planner', () => {
    let mockDispatch
    let weeklyState
    beforeAll(() => {
      MockDate.set('2017-04-19') // a Wednesday
    })

    afterAll(() => {
      MockDate.reset()
    })

    beforeEach(() => {
      mockDispatch = jest.fn(() => Promise.resolve({data: []}))
      weeklyState = getBasicState().weeklyDashboard
    })

    afterEach(() => {
      mockDispatch.mockReset()
    })

    describe('getWeeklyPlannerItems', () => {
      it('dispatches START_LOADING_ITEMS, gettingWeekItems, and starts the saga', async () => {
        const today = moment.tz('UTC').startOf('day')

        server.use(
          http.get(/\/api\/v1\/planner\/items/, ({request}) => {
            const url = new URL(request.url)
            if (url.searchParams.has('end_date')) {
              return HttpResponse.json([{plannable_date: '2017-05-01T:00:00:00Z'}])
            } else if (url.searchParams.has('start_date')) {
              return HttpResponse.json([{plannable_date: '2017-01-01T:00:00:00Z'}])
            }
            return HttpResponse.json([])
          }),
          http.get(/dashboard_cards/, () => HttpResponse.json({data: []})),
        )

        await Actions.getWeeklyPlannerItems(today)(mockDispatch, getBasicState)
        expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingItems())
        expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingInitWeekItems(weeklyState))
        expect(mockDispatch).toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({
            weekStart: weeklyState.weekStart,
            weekEnd: weeklyState.weekEnd,
            isPreload: false,
          }),
        )
        const getWayFutureItemThunk = mockDispatch.mock.calls[4][0] // the function returned by getWayFutureItem()
        expect(typeof getWayFutureItemThunk).toBe('function')

        const futurePromise = getWayFutureItemThunk(mockDispatch, getBasicState).then(() => {
          expect(mockDispatch).toHaveBeenCalledWith({
            type: 'GOT_WAY_FUTURE_ITEM_DATE',
            payload: '2017-05-01T:00:00:00Z',
          })
        })
        const getWayPastItemThunk = mockDispatch.mock.calls[5][0]
        expect(typeof getWayPastItemThunk).toBe('function')
        const pastPromise = getWayPastItemThunk(mockDispatch, getBasicState).then(() => {
          expect(mockDispatch).toHaveBeenCalledWith({
            type: 'GOT_WAY_PAST_ITEM_DATE',
            payload: '2017-01-01T:00:00:00Z',
          })
        })

        return Promise.all([futurePromise, pastPromise])
      })
    })

    describe('preloadSurroundingWeeks', () => {
      it('preloads previous week', () => {
        Actions.preloadSurroundingWeeks()(mockDispatch, getBasicState)
        expect(mockDispatch).toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({
            weekStart: weeklyState.weekStart.clone().add(-7, 'days'),
            weekEnd: weeklyState.weekEnd.clone().add(-7, 'days'),
            isPreload: true,
          }),
        )
      })

      it('preloads next week', () => {
        Actions.preloadSurroundingWeeks()(mockDispatch, getBasicState)
        expect(mockDispatch).toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({
            weekStart: weeklyState.weekStart.clone().add(7, 'days'),
            weekEnd: weeklyState.weekEnd.clone().add(7, 'days'),
            isPreload: true,
          }),
        )
      })
    })

    describe('loadPastWeekItems', () => {
      it('loads previous week items', () => {
        const lastWeek = {
          weekStart: weeklyState.weekStart.clone().add(-7, 'days'),
          weekEnd: weeklyState.weekEnd.clone().add(-7, 'days'),
        }
        const twoWeeksAgo = {
          weekStart: weeklyState.weekStart.clone().add(-14, 'days'),
          weekEnd: weeklyState.weekEnd.clone().add(-14, 'days'),
        }
        const getStateMock = jest
          .fn()
          .mockImplementationOnce(getBasicState) // loadPastWeekItems call
          .mockImplementation(() => {
            // loadWeekItems call
            const st = getBasicState()
            st.weeklyDashboard.weekStart = lastWeek.weekStart
            st.weeklyDashboard.weekEnd = lastWeek.weekEnd
            return st
          })
        Actions.loadPastWeekItems()(mockDispatch, getStateMock)
        expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingWeekItems(lastWeek))
        expect(mockDispatch).toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({...lastWeek, isPreload: false}),
        )
        // Pre-loading an additional week previous
        expect(mockDispatch).toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({...twoWeeksAgo, isPreload: true}),
        )
      })

      it('gets previous week from state if available', () => {
        const lastWeek = {
          weekStart: weeklyState.weekStart.clone().add(-7, 'days'),
          weekEnd: weeklyState.weekEnd.clone().add(-7, 'days'),
        }
        const twoWeeksAgo = {
          weekStart: weeklyState.weekStart.clone().add(-14, 'days'),
          weekEnd: weeklyState.weekEnd.clone().add(-14, 'days'),
        }
        const key = lastWeek.weekStart.format()
        const sunday = lastWeek.weekStart.format('YYYY-MM-DD')
        const lastWeekItems = [[sunday, 'this is it']]
        const getStateMock = jest.fn(() => {
          const st = getBasicState()
          st.weeklyDashboard.weeks = {
            [`${key}`]: lastWeekItems,
          }
          return st
        })
        Actions.loadPastWeekItems()(mockDispatch, getStateMock)
        expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingWeekItems(lastWeek))
        expect(mockDispatch).toHaveBeenCalledWith(Actions.jumpToWeek({weekDays: lastWeekItems}))
        // Doesn't pre-load an additional week if we already had the previous week in state
        expect(mockDispatch).not.toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({...twoWeeksAgo, isPreload: true}),
        )
      })
    })

    describe('loadNextWeekItems', () => {
      it('loads next week items', () => {
        const nextWeek = {
          weekStart: weeklyState.weekStart.clone().add(7, 'days'),
          weekEnd: weeklyState.weekEnd.clone().add(7, 'days'),
        }
        const twoWeeksHence = {
          weekStart: weeklyState.weekStart.clone().add(14, 'days'),
          weekEnd: weeklyState.weekEnd.clone().add(14, 'days'),
        }
        const getStateMock = jest
          .fn()
          .mockImplementationOnce(getBasicState) // loadPastWeekItems call
          .mockImplementation(() => {
            // loadWeekItems call
            const st = getBasicState()
            st.weeklyDashboard.weekStart = nextWeek.weekStart
            st.weeklyDashboard.weekEnd = nextWeek.weekEnd
            return st
          })
        Actions.loadNextWeekItems()(mockDispatch, getStateMock)
        expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingWeekItems(nextWeek))
        expect(mockDispatch).toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({...nextWeek, isPreload: false}),
        )
        // Pre-loading an additional week hence
        expect(mockDispatch).toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({...twoWeeksHence, isPreload: true}),
        )
      })

      it('gets next week from state if available', () => {
        const nextWeek = {
          weekStart: weeklyState.weekStart.clone().add(7, 'days'),
          weekEnd: weeklyState.weekEnd.clone().add(7, 'days'),
        }
        const twoWeeksHence = {
          weekStart: weeklyState.weekStart.clone().add(14, 'days'),
          weekEnd: weeklyState.weekEnd.clone().add(14, 'days'),
        }
        const key = nextWeek.weekStart.format()
        const sunday = nextWeek.weekStart.format('YYYY-MM-DD')
        const nextWeekItems = [[sunday, 'this is it']]
        const getStateMock = jest.fn(() => {
          const st = getBasicState()
          st.weeklyDashboard.weeks = {
            [`${key}`]: nextWeekItems,
          }
          return st
        })
        Actions.loadNextWeekItems()(mockDispatch, getStateMock)
        expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingWeekItems(nextWeek))
        expect(mockDispatch).toHaveBeenCalledWith(Actions.jumpToWeek({weekDays: nextWeekItems}))
        // Doesn't pre-load an additional week if we already had the next week in state
        expect(mockDispatch).not.toHaveBeenCalledWith(
          Actions.startLoadingWeekSaga({...twoWeeksHence, isPreload: true}),
        )
      })
    })

    describe('loadThisWeekItems', () => {
      it('jump to this week', () => {
        const thisWeek = {
          weekStart: weeklyState.weekStart.clone(),
          weekEnd: weeklyState.weekEnd.clone(),
        }
        const getStateMock = jest.fn().mockImplementation(() => {
          const state = getBasicState()
          state.weeklyDashboard = {
            weekStart: thisWeek.weekStart,
            weekEnd: thisWeek.weekEnd,
            thisWeek: thisWeek.weekStart,
            weeks: {
              [thisWeek.weekStart.format()]: thisWeek,
            },
          }
          return state
        })
        Actions.loadThisWeekItems()(mockDispatch, getStateMock)
        expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingWeekItems(thisWeek))
        expect(mockDispatch).toHaveBeenCalledWith(Actions.jumpToThisWeek({weekDays: thisWeek}))
      })
    })

    it('filters requests to specific contexts if in singleCourse mode', async () => {
      const today = moment.tz('UTC').startOf('day')
      const capturedUrls = []

      server.use(
        http.get(/\/api\/v1\/planner\/items/, ({request}) => {
          capturedUrls.push(request.url)
          return HttpResponse.json([{plannable_date: '2017-05-01T:00:00:00Z'}])
        }),
      )

      const mockUiManager = {
        setStore: jest.fn(),
        handleAction: jest.fn(),
        uiStateUnchanged: jest.fn(),
      }

      const store = configureStore(mockUiManager, {
        ...getBasicState(),
        courses: [{id: '7', assetString: 'course_7'}],
        singleCourse: true,
      })
      await store.dispatch(Actions.getWeeklyPlannerItems(today))

      const expectedContextCodes = /context_codes%5B%5D=course_7/
      // Fetching current week, far future date, and far past date should all be filtered by context_codes
      expect(capturedUrls).toHaveLength(3)
      expect(capturedUrls[0]).toMatch(expectedContextCodes)
      expect(capturedUrls[1]).toMatch(expectedContextCodes)
      expect(capturedUrls[2]).toMatch(expectedContextCodes)
    })

    it('adds observee id, account calendars flag and all_courses flag to request if state contains selected observee', async () => {
      const today = moment.tz('UTC').startOf('day')
      const capturedUrls = []

      server.use(
        http.get(/\/api\/v1\/planner\/items/, ({request}) => {
          capturedUrls.push(request.url)
          return HttpResponse.json([{plannable_date: '2017-05-01T:00:00:00Z'}])
        }),
        http.get(/dashboard_cards/, ({request}) => {
          capturedUrls.push(request.url)
          return HttpResponse.json([
            {id: '11', assetString: 'course_11'},
            {id: '12', assetString: 'course_12'},
          ])
        }),
      )

      const mockUiManager = {
        setStore: jest.fn(),
        handleAction: jest.fn(),
        uiStateUnchanged: jest.fn(),
      }

      const store = configureStore(mockUiManager, {
        ...getBasicState(),
        selectedObservee: '35',
      })

      await store.dispatch(Actions.getWeeklyPlannerItems(today))

      const expectedParams =
        /include%5B%5D=account_calendars&include%5B%5D=all_courses&per_page=100&observed_user_id=35/
      const expectedParamsPastRequest =
        /include%5B%5D=account_calendars&include%5B%5D=all_courses&order=asc&per_page=1&observed_user_id=35/
      const expectedParamsFutureRequest =
        /include%5B%5D=account_calendars&include%5B%5D=all_courses&order=desc&per_page=1&observed_user_id=35/
      // For multi-course mode, fetching current week, far future date, and far past date should all have observee id
      // , account calendars flag and context codes
      expect(capturedUrls).toHaveLength(4)
      expect(capturedUrls[0]).toMatch(/dashboard_cards/)
      expect(capturedUrls[1]).toMatch(expectedParamsFutureRequest)
      expect(capturedUrls[2]).toMatch(expectedParamsPastRequest)
      expect(capturedUrls[3]).toMatch(expectedParams)
    })

    it('does not add the account calendars flag if state contains selected observee in singleCourse mode', async () => {
      const today = moment.tz('UTC').startOf('day')
      const capturedUrls = []

      server.use(
        http.get(/\/api\/v1\/planner\/items/, ({request}) => {
          capturedUrls.push(request.url)
          return HttpResponse.json([{plannable_date: '2017-05-01T:00:00:00Z'}])
        }),
      )

      const mockUiManager = {
        setStore: jest.fn(),
        handleAction: jest.fn(),
        uiStateUnchanged: jest.fn(),
      }

      const store = configureStore(mockUiManager, {
        ...getBasicState(),
        courses: [{id: '11', assetString: 'course_11'}],
        selectedObservee: '35',
        singleCourse: true,
      })

      await store.dispatch(Actions.getWeeklyPlannerItems(today))
      const expectedParams = /observed_user_id=35&context_codes%5B%5D=course_11/
      // For single-course mode, fetching current week, far future date, and far past date should all have observee id and context codes
      expect(capturedUrls).toHaveLength(3)
      expect(capturedUrls[0]).toMatch(expectedParams)
      expect(capturedUrls[1]).toMatch(expectedParams)
      expect(capturedUrls[2]).toMatch(expectedParams)
    })

    it('does not add observee id if observee id is the current user id', async () => {
      const today = moment.tz('UTC').startOf('day')
      const capturedUrls = []

      server.use(
        http.get(/\/api\/v1\/planner\/items/, ({request}) => {
          capturedUrls.push(request.url)
          return HttpResponse.json([{plannable_date: '2017-05-01T:00:00:00Z'}])
        }),
        http.get(/dashboard_cards/, ({request}) => {
          capturedUrls.push(request.url)
          return HttpResponse.json([{id: '7', assetString: 'course_7'}])
        }),
      )

      const mockUiManager = {
        setStore: jest.fn(),
        handleAction: jest.fn(),
        uiStateUnchanged: jest.fn(),
      }

      const store = configureStore(mockUiManager, {
        ...getBasicState(),
        selectedObservee: '1',
      })

      await store.dispatch(Actions.getWeeklyPlannerItems(today))

      expect(capturedUrls).toHaveLength(4)
      expect(capturedUrls[0]).toMatch(/dashboard_cards/)
      expect(capturedUrls[0]).not.toContain('observed_user_id')
      expect(capturedUrls[1]).not.toContain('observed_user_id')
      expect(capturedUrls[2]).not.toContain('observed_user_id')
      expect(capturedUrls[3]).not.toContain('observed_user_id')
    })
  })
})

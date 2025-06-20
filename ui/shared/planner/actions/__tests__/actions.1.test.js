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
import {isPromise} from '@canvas/jest-moxios-utils'
import * as SidebarActions from '../sidebar-actions'
import * as Actions from '../index'
import {initialize as alertInitialize} from '../../utilities/alertUtils'

jest.mock('../../utilities/apiUtils', () => ({
  ...jest.requireActual('../../utilities/apiUtils'),
  transformApiToInternalItem: jest.fn(response => ({...response, transformedToInternal: true})),
  transformInternalToApiItem: jest.fn(internal => ({...internal, transformedToApi: true})),
  transformInternalToApiOverride: jest.fn(internal => ({
    ...internal.planner_override,
    marked_complete: null,
    transformedToApiOverride: true,
  })),
  transformPlannerNoteApiToInternalItem: jest.fn(response => ({
    ...response,
    transformedToInternal: true,
  })),
}))

const simpleItem = opts => ({some: 'data', date: moment('2018-03-28T13:14:00-04:00'), ...opts})

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
    allOpportunitiesLoaded: true,
  },
  currentUser: {id: '1', displayName: 'Jane', avatarUrl: '/avatar/is/here', color: '#03893D'},
  opportunities: {
    items: [
      {id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
      {id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false},
      {id: 3, firstName: 'Tommy', lastName: 'Flintstone', dismissed: false},
      {id: 4, firstName: 'Bill', lastName: 'Flintstone', dismissed: false},
      {id: 5, firstName: 'George', lastName: 'Flintstone', dismissed: false},
      {id: 6, firstName: 'Randel', lastName: 'Flintstone', dismissed: false},
      {id: 7, firstName: 'Harry', lastName: 'Flintstone', dismissed: false},
      {id: 8, firstName: 'Tim', lastName: 'Flintstone', dismissed: false},
      {id: 9, firstName: 'Sara', lastName: 'Flintstone', dismissed: false},
    ],
    nextUrl: null,
  },
  ui: {
    gradesTrayOpen: false,
  },
})

const server = setupServer()

describe('api actions', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    SidebarActions.maybeUpdateTodoSidebar.reset()
  })
  afterAll(() => server.close())

  beforeEach(() => {
    expect.hasAssertions()
    alertInitialize({
      visualSuccessCallback() {},
      visualErrorCallback() {},
      srAlertCallback() {},
    })
  })

  describe('getNextOpportunities', () => {
    it('if no more pages dispatches addOpportunities with items and null url', async () => {
      server.use(
        http.get('*', () => {
          return new HttpResponse(
            JSON.stringify([
              {id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
              {id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false},
            ]),
            {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
                link: '</>; rel="current"',
              },
            },
          )
        }),
      )

      const mockDispatch = jest.fn(action => {
        // If the action returns a promise, resolve it
        if (isPromise(action)) {
          return action
        }
      })
      const state = getBasicState()
      state.opportunities.nextUrl = '/'
      const getState = () => {
        return state
      }
      await Actions.getNextOpportunities()(mockDispatch, getState)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_OPPORTUNITIES'})
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'ADD_OPPORTUNITIES',
        payload: {
          items: [
            {id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
            {id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false},
          ],
          nextUrl: null,
        },
      })
    })
    it('if nextUrl not set show all opportunities loaded', () => {
      const mockDispatch = jest.fn()
      const state = getBasicState()
      state.opportunities.nextUrl = null
      const getState = () => {
        return state
      }
      Actions.getNextOpportunities()(mockDispatch, getState)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_OPPORTUNITIES'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'ALL_OPPORTUNITIES_LOADED'})
    })
  })

  describe('getOpportunities', () => {
    it('dispatches startLoading and initialOpportunities actions', async () => {
      server.use(
        http.get('*', () => {
          return new HttpResponse(
            JSON.stringify([
              {id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
              {id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false},
            ]),
            {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
                link: '</>; rel="next"',
              },
            },
          )
        }),
      )

      const mockDispatch = jest.fn(action => {
        // If the action returns a promise, resolve it
        if (isPromise(action)) {
          return action
        }
      })
      await Actions.getInitialOpportunities()(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_OPPORTUNITIES'})
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'ADD_OPPORTUNITIES',
        payload: {
          items: [
            {id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
            {id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false},
          ],
          nextUrl: '/',
        },
      })
    })

    it('dispatches startDismissingOpportunity and dismissedOpportunity actions', async () => {
      server.use(
        http.put('/api/v1/planner/overrides/10', () => {
          return HttpResponse.json(
            [
              {id: 1, firstName: 'Fred', lastName: 'Flintstone'},
              {id: 2, firstName: 'Wilma', lastName: 'Flintstone'},
            ],
            {status: 201},
          )
        }),
      )

      const mockDispatch = jest.fn()
      const plannerOverride = {
        id: '10',
        plannable_type: 'assignment',
        dismissed: true,
      }
      await Actions.dismissOpportunity('6', plannerOverride)(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith({
        payload: '6',
        type: 'START_DISMISSING_OPPORTUNITY',
      })
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'DISMISSED_OPPORTUNITY',
        payload: [
          {id: 1, firstName: 'Fred', lastName: 'Flintstone'},
          {id: 2, firstName: 'Wilma', lastName: 'Flintstone'},
        ],
      })
    })

    it('dispatches startDismissingOpportunity and dismissedOpportunity actions when given override', async () => {
      server.use(
        http.put('/api/v1/planner/overrides/6', () => {
          return HttpResponse.json(
            [
              {id: 1, firstName: 'Fred', lastName: 'Flintstone'},
              {id: 2, firstName: 'Wilma', lastName: 'Flintstone'},
            ],
            {status: 201},
          )
        }),
      )

      const mockDispatch = jest.fn()
      await Actions.dismissOpportunity('6', {id: '6'})(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith({
        payload: '6',
        type: 'START_DISMISSING_OPPORTUNITY',
      })
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'DISMISSED_OPPORTUNITY',
        payload: [
          {id: 1, firstName: 'Fred', lastName: 'Flintstone'},
          {id: 2, firstName: 'Wilma', lastName: 'Flintstone'},
        ],
      })
    })

    it('makes correct request for dismissedOpportunity for existing override', async () => {
      let capturedRequest
      server.use(
        http.put('/api/v1/planner/overrides/10', async ({request}) => {
          capturedRequest = {
            method: request.method,
            url: request.url,
            body: await request.json(),
          }
          return HttpResponse.json([], {status: 201})
        }),
      )

      const plannerOverride = {
        id: '10',
        plannable_type: 'assignment',
        dismissed: true,
      }
      await Actions.dismissOpportunity('6', plannerOverride)(() => {})
      expect(capturedRequest.method).toBe('PUT')
      expect(capturedRequest.url).toBe('http://localhost/api/v1/planner/overrides/10')
      expect(capturedRequest.body).toMatchObject(plannerOverride)
    })

    it('makes correct request for dismissedOpportunity for new override', async () => {
      let capturedRequest
      server.use(
        http.post('/api/v1/planner/overrides', async ({request}) => {
          capturedRequest = {
            method: request.method,
            url: request.url,
            body: await request.json(),
          }
          return HttpResponse.json([], {status: 201})
        }),
      )

      const plannerOverride = {
        plannable_id: '10',
        dismissed: true,
        plannable_type: 'assignment',
      }
      await Actions.dismissOpportunity('10', plannerOverride)(() => {})
      expect(capturedRequest.method).toBe('POST')
      expect(capturedRequest.url).toBe('http://localhost/api/v1/planner/overrides')
      expect(capturedRequest.body).toMatchObject(plannerOverride)
    })

    it('calls the alert function when dismissing an opportunity fails', async () => {
      server.use(
        http.put('/api/v1/planner/overrides/6', () => {
          return new HttpResponse(null, {status: 400})
        }),
      )

      const fakeAlert = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })
      await Actions.dismissOpportunity('6', {id: '6'})(() => {})
      expect(fakeAlert).toHaveBeenCalled()
    })

    it('calls the alert function when a failure occurs', async () => {
      server.use(
        http.get('*', () => {
          return new HttpResponse(null, {status: 500})
        }),
      )

      const mockDispatch = jest.fn(action => {
        // If the action returns a promise, resolve it
        if (isPromise(action)) {
          return action
        }
      })
      const fakeAlert = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })
      await Actions.getInitialOpportunities()(mockDispatch, getBasicState)
      expect(fakeAlert).toHaveBeenCalled()
    })
  })
})

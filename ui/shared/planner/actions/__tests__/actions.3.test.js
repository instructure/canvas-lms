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
    marked_complete: internal.marked_complete ?? false,
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

  describe('togglePlannerItemCompletion', () => {
    it('dispatches saving, saved, and maybe update sidebar actions', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem()
      const savingItem = {...plannerItem, show: true, toggleAPIPending: true}
      const savePromise = Actions.togglePlannerItemCompletion(plannerItem)(
        mockDispatch,
        getBasicState,
      )
      expect(isPromise(savePromise)).toBe(true)
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'SAVING_PLANNER_ITEM',
        payload: {item: savingItem, isNewItem: false, wasToggled: true},
      })
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVED_PLANNER_ITEM', payload: savePromise})
      expect(mockDispatch).toHaveBeenCalledWith(SidebarActions.maybeUpdateTodoSidebar)
      expect(SidebarActions.maybeUpdateTodoSidebar.args()).toEqual([savePromise])
    })

    it('updates marked_complete and sends override data in the request', async () => {
      let capturedRequest
      server.use(
        http.post('/api/v1/planner/overrides', async ({request}) => {
          capturedRequest = await request.json()
          return HttpResponse.json({}, {status: 201})
        }),
      )

      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({marked_complete: null})
      await Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState)
      expect(capturedRequest).toMatchObject({
        marked_complete: true,
        transformedToApiOverride: true,
      })
    })

    it('does a post if the planner override is new (no id)', async () => {
      let capturedRequest
      server.use(
        http.post('/api/v1/planner/overrides', async ({request}) => {
          capturedRequest = {
            method: request.method,
            url: request.url,
            body: await request.json(),
          }
          return HttpResponse.json({}, {status: 201})
        }),
      )

      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({id: '42'})
      await Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState)
      expect(capturedRequest.method).toBe('POST')
      expect(capturedRequest.url).toBe('http://localhost/api/v1/planner/overrides')
      expect(capturedRequest.body).toMatchObject({
        marked_complete: true,
        transformedToApiOverride: true,
      })
    })

    it('does a put if the planner override exists (has id)', async () => {
      let capturedRequest
      server.use(
        http.put('/api/v1/planner/overrides/5', async ({request}) => {
          capturedRequest = {
            method: request.method,
            url: request.url,
            body: await request.json(),
          }
          return HttpResponse.json({}, {status: 200})
        }),
      )

      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({id: '42', planner_override: {id: '5', marked_complete: true}})
      await Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState)
      expect(capturedRequest.method).toBe('PUT')
      expect(capturedRequest.url).toBe('http://localhost/api/v1/planner/overrides/5')
      expect(capturedRequest.body).toMatchObject({
        id: '5',
        marked_complete: true,
        transformedToApiOverride: true,
      })
    })

    it('resolves the promise with override response data in the item', async () => {
      server.use(
        http.put('/api/v1/planner/overrides/override_id', () => {
          return HttpResponse.json(
            {some: 'response data', id: 'override_id', marked_complete: false},
            {status: 200},
          )
        }),
      )

      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({planner_override: {id: 'override_id', marked_complete: true}})
      const result = await Actions.togglePlannerItemCompletion(plannerItem)(
        mockDispatch,
        getBasicState,
      )
      expect(result).toMatchObject({
        wasToggled: true,
        item: {
          ...plannerItem,
          completed: false,
          overrideId: 'override_id',
          show: true,
        },
      })
    })

    it('calls the alert function and resends previous override when a failure occurs', async () => {
      server.use(
        http.put('/api/v1/planner/overrides/override_id', () => {
          return new HttpResponse(null, {status: 500})
        }),
      )

      const fakeAlert = jest.fn()
      const mockDispatch = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })

      const plannerItem = {
        some: 'data',
        planner_override: {id: 'override_id', marked_complete: false},
      }
      const result = await Actions.togglePlannerItemCompletion(plannerItem)(
        mockDispatch,
        getBasicState,
      )
      expect(fakeAlert).toHaveBeenCalled()
      expect(result).toMatchObject({
        item: {...plannerItem},
        wasToggled: true,
      })
    })
  })

  describe('cancelEditingPlannerItem', () => {
    it('dispatches clearUpdateTodo and canceledEditingPlannerItem actions', () => {
      const mockDispatch = jest.fn()
      Actions.cancelEditingPlannerItem()(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_UPDATE_TODO'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CANCELED_EDITING_PLANNER_ITEM'})
    })
  })
})

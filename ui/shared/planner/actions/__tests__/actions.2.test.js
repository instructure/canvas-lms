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

import moxios from 'moxios'
import moment from 'moment-timezone'
import {isPromise, moxiosWait, moxiosRespond} from '@canvas/jest-moxios-utils'
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
  currentUser: {id: '1', displayName: 'Jane', avatarUrl: '/avatar/is/here', color: '#0B874B'},
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

describe('api actions', () => {
  beforeEach(() => {
    moxios.install()
    expect.hasAssertions()
    alertInitialize({
      visualSuccessCallback() {},
      visualErrorCallback() {},
      srAlertCallback() {},
    })
  })

  afterEach(() => {
    moxios.uninstall()
    SidebarActions.maybeUpdateTodoSidebar.reset()
  })

  describe('savePlannerItem', () => {
    it('dispatches saving, clearUpdateTodo, and saved actions', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem()
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState)
      expect(isPromise(savePromise)).toBe(true)
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'SAVING_PLANNER_ITEM',
        payload: {item: plannerItem, isNewItem: true},
      })
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_UPDATE_TODO'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVED_PLANNER_ITEM', payload: savePromise})
    })

    it('sets isNewItem to false if the item id exists', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({id: '42'})
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState)
      expect(isPromise(savePromise)).toBe(true)
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'SAVING_PLANNER_ITEM',
        payload: {item: plannerItem, isNewItem: false},
      })
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_UPDATE_TODO'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVED_PLANNER_ITEM', payload: savePromise})
    })

    it('sends transformed data in the request', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem()
      Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState)
      return moxiosWait(request => {
        expect(JSON.parse(request.config.data)).toMatchObject({
          some: 'data',
          transformedToApi: true,
        })
      })
    })

    it('resolves the promise with transformed response data', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem()
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState)
      return moxiosRespond({some: 'response data'}, savePromise).then(result => {
        expect(result).toMatchObject({
          item: {some: 'response data', transformedToInternal: true},
          isNewItem: true,
        })
      })
    })

    it('does a post if the planner item is new (no id)', () => {
      const plannerItem = simpleItem()
      Actions.savePlannerItem(plannerItem)(
        () => {},
        () => {
          return {timeZone: 'America/Halifax'}
        },
      )
      return moxiosWait(request => {
        expect(request.config.method).toBe('post')
        expect(request.url).toBe('/api/v1/planner_notes')
        expect(JSON.parse(request.config.data)).toMatchObject({
          some: 'data',
          transformedToApi: true,
        })
      })
    })

    it('does a put if the planner item exists (has id)', () => {
      const plannerItem = simpleItem({id: '42'})
      Actions.savePlannerItem(plannerItem)(
        () => {},
        () => {
          return {timeZone: 'America/Halifax'}
        },
      )
      return moxiosWait(request => {
        expect(request.config.method).toBe('put')
        expect(request.url).toBe('/api/v1/planner_notes/42')
        expect(JSON.parse(request.config.data)).toMatchObject({
          id: '42',
          some: 'data',
          transformedToApi: true,
        })
      })
    })

    it('calls the alert function when a failure occurs', () => {
      const fakeAlert = jest.fn()
      const mockDispatch = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })

      const plannerItem = simpleItem()
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState)
      return moxiosRespond({some: 'response data'}, savePromise, {status: 500}).then(_result => {
        expect(fakeAlert).toHaveBeenCalled()
      })
    })

    it('saves and restores the override data', () => {
      const mockDispatch = jest.fn()
      // a planner item with override data
      const plannerItem = simpleItem({id: '42', overrideId: '17', completed: true})
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState)
      return moxiosRespond(
        {some: 'data', id: '42'}, // notice the response has no override data
        savePromise,
        {status: 200},
      ).then(result => {
        expect(result).toMatchObject({
          // yet the resolved item does have override data
          item: {
            some: 'data',
            id: '42',
            overrideId: '17',
            completed: true,
            show: true,
            transformedToInternal: true,
          },
          isNewItem: false,
        })
      })
    })
  })

  describe('deletePlannerItem', () => {
    it('dispatches deleting, clearUpdateTodo, deleted, and maybe update sidebar actions', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem()
      const deletePromise = Actions.deletePlannerItem(plannerItem)(mockDispatch, getBasicState)
      expect(isPromise(deletePromise)).toBe(true)
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'DELETING_PLANNER_ITEM',
        payload: plannerItem,
      })
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_UPDATE_TODO'})
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'DELETED_PLANNER_ITEM',
        payload: deletePromise,
      })
      expect(mockDispatch).toHaveBeenCalledWith(SidebarActions.maybeUpdateTodoSidebar)
    })

    it('sends a delete request for the item id', () => {
      const plannerItem = simpleItem({id: '42'})
      Actions.deletePlannerItem(plannerItem)(() => {})
      return moxiosWait(request => {
        expect(request.config.method).toBe('delete')
        expect(request.url).toBe('/api/v1/planner_notes/42')
      })
    })

    it('resolves the promise with transformed response data', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem()
      const deletePromise = Actions.deletePlannerItem(plannerItem)(mockDispatch, getBasicState)
      return moxiosRespond({some: 'response data'}, deletePromise).then(result => {
        expect(result).toMatchObject({some: 'response data', transformedToInternal: true})
      })
    })

    it('calls the alert function when a failure occurs', () => {
      const fakeAlert = jest.fn()
      const mockDispatch = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })

      const plannerItem = simpleItem()
      const deletePromise = Actions.deletePlannerItem(plannerItem)(mockDispatch, getBasicState)
      return moxiosRespond({some: 'response data'}, deletePromise, {status: 500}).then(
        __staticRouterHydrationDataresult => {
          expect(fakeAlert).toHaveBeenCalled()
        },
      )
    })
  })
})

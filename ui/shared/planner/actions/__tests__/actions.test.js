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

/* eslint-disable promise/catch-or-return */
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

  describe('getNextOpportunities', () => {
    it('if no more pages dispatches addOpportunities with items and null url', () => {
      const mockDispatch = jest.fn()
      const state = getBasicState()
      state.opportunities.nextUrl = '/'
      const getState = () => {
        return state
      }
      Actions.getNextOpportunities()(mockDispatch, getState)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_OPPORTUNITIES'})
      return moxiosWait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 200,
            headers: {
              link: `</>; rel="current"`,
            },
            response: [
              {id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
              {id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false},
            ],
          })
          .then(() => {
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
    it('dispatches startLoading and initialOpportunities actions', () => {
      const mockDispatch = jest.fn()
      Actions.getInitialOpportunities()(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_OPPORTUNITIES'})
      return moxiosWait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 200,
            headers: {
              link: `</>; rel="next"`,
            },
            response: [
              {id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
              {id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false},
            ],
          })
          .then(() => {
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
      })
    })

    it('dispatches startDismissingOpportunity and dismissedOpportunity actions', () => {
      const mockDispatch = jest.fn()
      const plannerOverride = {
        id: '10',
        plannable_type: 'assignment',
        dismissed: true,
      }
      Actions.dismissOpportunity('6', plannerOverride)(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith({
        payload: '6',
        type: 'START_DISMISSING_OPPORTUNITY',
      })
      return moxiosWait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 201,
            response: [
              {id: 1, firstName: 'Fred', lastName: 'Flintstone'},
              {id: 2, firstName: 'Wilma', lastName: 'Flintstone'},
            ],
          })
          .then(() => {
            expect(mockDispatch).toHaveBeenCalledWith({
              type: 'DISMISSED_OPPORTUNITY',
              payload: [
                {id: 1, firstName: 'Fred', lastName: 'Flintstone'},
                {id: 2, firstName: 'Wilma', lastName: 'Flintstone'},
              ],
            })
          })
      })
    })

    it('dispatches startDismissingOpportunity and dismissedOpportunity actions when given override', () => {
      const mockDispatch = jest.fn()
      Actions.dismissOpportunity('6', {id: '6'})(mockDispatch, getBasicState)
      expect(mockDispatch).toHaveBeenCalledWith({
        payload: '6',
        type: 'START_DISMISSING_OPPORTUNITY',
      })
      return moxiosWait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 201,
            response: [
              {id: 1, firstName: 'Fred', lastName: 'Flintstone'},
              {id: 2, firstName: 'Wilma', lastName: 'Flintstone'},
            ],
          })
          .then(() => {
            expect(mockDispatch).toHaveBeenCalledWith({
              type: 'DISMISSED_OPPORTUNITY',
              payload: [
                {id: 1, firstName: 'Fred', lastName: 'Flintstone'},
                {id: 2, firstName: 'Wilma', lastName: 'Flintstone'},
              ],
            })
          })
      })
    })

    it('makes correct request for dismissedOpportunity for existing override', () => {
      const plannerOverride = {
        id: '10',
        plannable_type: 'assignment',
        dismissed: true,
      }
      Actions.dismissOpportunity('6', plannerOverride)(() => {})
      return moxiosWait(request => {
        expect(request.config.method).toBe('put')
        expect(request.url).toBe('/api/v1/planner/overrides/10')
        expect(JSON.parse(request.config.data)).toMatchObject(plannerOverride)
      })
    })

    it('makes correct request for dismissedOpportunity for new override', () => {
      const plannerOverride = {
        plannable_id: '10',
        dismissed: true,
        plannable_type: 'assignment',
      }
      Actions.dismissOpportunity('10', plannerOverride)(() => {})
      return moxiosWait(request => {
        expect(request.config.method).toBe('post')
        expect(request.url).toBe('/api/v1/planner/overrides')
        expect(JSON.parse(request.config.data)).toMatchObject(plannerOverride)
      })
    })

    it('calls the alert function when dismissing an opportunity fails', done => {
      const fakeAlert = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })
      Actions.dismissOpportunity('6', {id: '6'})(() => {})
      moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 400,
          })
          .then(() => {
            expect(fakeAlert).toHaveBeenCalled()
            // eslint-disable-next-line promise/no-callback-in-promise
            done()
          })
      })
    })

    it('calls the alert function when a failure occurs', done => {
      const mockDispatch = jest.fn()
      const fakeAlert = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })
      Actions.getInitialOpportunities()(mockDispatch, getBasicState)
      moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        request
          .respondWith({
            status: 500,
          })
          .then(() => {
            expect(fakeAlert).toHaveBeenCalled()
            // eslint-disable-next-line promise/no-callback-in-promise
            done()
          })
      })
    })
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
        }
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
        }
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
        {status: 200}
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
        }
      )
    })
  })

  describe('togglePlannerItemCompletion', () => {
    it('dispatches saving, saved, and maybe update sidebar actions', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem()
      const savingItem = {...plannerItem, show: true, toggleAPIPending: true}
      const savePromise = Actions.togglePlannerItemCompletion(plannerItem)(
        mockDispatch,
        getBasicState
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

    it('updates marked_complete and sends override data in the request', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({marked_complete: null})
      Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState)
      return moxiosWait(request => {
        expect(JSON.parse(request.config.data)).toMatchObject({
          marked_complete: true,
          transformedToApiOverride: true,
        })
      })
    })

    it('does a post if the planner override is new (no id)', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({id: '42'})
      Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState)
      return moxiosWait(request => {
        expect(request.config.method).toBe('post')
        expect(request.url).toBe('/api/v1/planner/overrides')
        expect(JSON.parse(request.config.data)).toMatchObject({
          marked_complete: true,
          transformedToApiOverride: true,
        })
      })
    })

    it('does a put if the planner override exists (has id)', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({id: '42', planner_override: {id: '5', marked_complete: true}})
      Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState)
      return moxiosWait(request => {
        expect(request.config.method).toBe('put')
        expect(request.url).toBe('/api/v1/planner/overrides/5')
        expect(JSON.parse(request.config.data)).toMatchObject({
          id: '5',
          marked_complete: true,
          transformedToApiOverride: true,
        })
      })
    })

    it('resolves the promise with override response data in the item', () => {
      const mockDispatch = jest.fn()
      const plannerItem = simpleItem({planner_override: {id: 'override_id', marked_complete: true}})
      const togglePromise = Actions.togglePlannerItemCompletion(plannerItem)(
        mockDispatch,
        getBasicState
      )
      return moxiosRespond(
        {some: 'response data', id: 'override_id', marked_complete: false},
        togglePromise
      ).then(result => {
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
    })

    it('calls the alert function and resends previous override when a failure occurs', () => {
      const fakeAlert = jest.fn()
      const mockDispatch = jest.fn()
      alertInitialize({
        visualErrorCallback: fakeAlert,
      })

      const plannerItem = {
        some: 'data',
        planner_override: {id: 'override_id', marked_complete: false},
      }
      const togglePromise = Actions.togglePlannerItemCompletion(plannerItem)(
        mockDispatch,
        getBasicState
      )
      return moxiosRespond({some: 'response data'}, togglePromise, {status: 500}).then(result => {
        expect(fakeAlert).toHaveBeenCalled()
        expect(result).toMatchObject({
          item: {...plannerItem},
          wasToggled: true,
        })
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

  describe('clearItems', () => {
    it('dispatches clearWeeklyItems and clearOpportunities actions', () => {
      const mockDispatch = jest.fn()
      Actions.clearItems()(mockDispatch, () => ({
        weeklyDashboard: {},
      }))
      expect(mockDispatch).toHaveBeenCalledTimes(6)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_WEEKLY_ITEMS'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_OPPORTUNITIES'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_DAYS'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_COURSES'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_SIDEBAR'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_LOADING'})
    })

    it('does not dispatch clearWeeklyItems if not a weekly dashboard', () => {
      const mockDispatch = jest.fn()
      Actions.clearItems()(mockDispatch, () => ({}))
      expect(mockDispatch).toHaveBeenCalledTimes(5)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_OPPORTUNITIES'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_DAYS'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_COURSES'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_SIDEBAR'})
      expect(mockDispatch).toHaveBeenCalledWith({type: 'CLEAR_LOADING'})
    })
  })

  describe('reloadWithObservee', () => {
    let mockDispatch, store, getState
    beforeEach(() => {
      mockDispatch = jest.fn(() => Promise.resolve({data: []}))
      store = {...getBasicState()}
      getState = () => store
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

    it('does nothing if no observee id', () => {
      Actions.reloadWithObservee(undefined)(mockDispatch, getState)
      expect(mockDispatch).not.toHaveBeenCalled()
    })

    it('does nothing if the observee id did not change', () => {
      store.selectedObservee = '5'

      Actions.reloadWithObservee('5')(mockDispatch, getState)
      expect(mockDispatch).not.toHaveBeenCalled()
    })

    it('dispatches startLoadingItems if contextCodes are not present but observee id changed', async () => {
      store.selectedObservee = '5'

      await Actions.reloadWithObservee('6')(mockDispatch, getState)
      expect(mockDispatch).toHaveBeenCalledTimes(4)
      expect(mockDispatch).toHaveBeenCalledWith({
        payload: '6',
        type: 'SELECTED_OBSERVEE',
      })
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_ALL_OPPORTUNITIES'})
    })

    it('dispatches start if contextCodes are not present but observee id changed', async () => {
      store.selectedObservee = '5'
      store.ui.gradesTrayOpen = true

      await Actions.reloadWithObservee('6')(mockDispatch, getState)
      expect(mockDispatch).toHaveBeenCalledTimes(5)
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_GRADES_SAGA', payload: '6'})
    })
  })
})

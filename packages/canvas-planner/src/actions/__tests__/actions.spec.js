/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import * as Actions from '../index';
import moxios from 'moxios';
import moment from 'moment-timezone';
import {isPromise, moxiosWait, moxiosRespond} from '../../test-utils';
import { initialize as alertInitialize } from '../../utilities/alertUtils';

jest.mock('../../utilities/apiUtils', () => ({
  transformApiToInternalItem: jest.fn(response => ({...response, transformedToInternal: true})),
  transformInternalToApiItem: jest.fn(internal => ({...internal, transformedToApi: true})),
  transformInternalToApiOverride: jest.fn(internal => ({...internal.planner_override, marked_complete: null, transformedToApiOverride: true})),
  transformPlannerNoteApiToInternalItem: jest.fn(response => ({...response, transformedToInternal: true}))
}));

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
  currentUser: {id: '1', displayName: 'Jane', avatarUrl: '/avatar/is/here'},
  opportunities: {
    items: [
      { id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
      { id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false },
      { id: 3, firstName: 'Tommy', lastName: 'Flintstone', dismissed: false },
      { id: 4, firstName: 'Bill', lastName: 'Flintstone', dismissed: false },
      { id: 5, firstName: 'George', lastName: 'Flintstone', dismissed: false },
      { id: 6, firstName: 'Randel', lastName: 'Flintstone', dismissed: false },
      { id: 7, firstName: 'Harry', lastName: 'Flintstone', dismissed: false },
      { id: 8, firstName: 'Tim', lastName: 'Flintstone', dismissed: false },
      { id: 9, firstName: 'Sara', lastName: 'Flintstone', dismissed: false }
    ],
    nextUrl: null
  }
});

describe('api actions', () => {
  beforeEach(() => {
    moxios.install();
    expect.hasAssertions();
    alertInitialize({
      visualSuccessCallback () {},
      visualErrorCallback () {},
      srAlertCallback () {}
    });
  });

  afterEach(() => {
    moxios.uninstall();
  });

  describe('getNextOpportunities', () => {
    it('if no more pages dispatches addOpportunities with items and null url', () => {
      const mockDispatch = jest.fn();
      var state = getBasicState();
      state.opportunities.nextUrl = '/';
      const getState = () => {
        return state;
      };
      Actions.getNextOpportunities()(mockDispatch, getState);
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_OPPORTUNITIES'});
      return moxiosWait(() => {
        let request = moxios.requests.mostRecent();
        request.respondWith({
          status: 200,
          headers: {
            link: `</>; rel="current"`
          },
          response: [
            { id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
            { id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false }
          ]
        }).then(() => {
          expect(mockDispatch).toHaveBeenCalledWith({type: 'ADD_OPPORTUNITIES', payload: {
            items: [
              { id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
              { id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false }
            ], nextUrl : null
          }});
        });
      });
    });
    it('if nextUrl not set show all opportunities loaded', () => {
      const mockDispatch = jest.fn();
      var state = getBasicState();
      state.opportunities.nextUrl = null;
      const getState = () => {
        return state;
      };
      Actions.getNextOpportunities()(mockDispatch, getState);
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_OPPORTUNITIES'});
      expect(mockDispatch).toHaveBeenCalledWith({type: 'ALL_OPPORTUNITIES_LOADED'});
    });
  });

  describe('getOpportunities', () => {
    it('dispatches startLoading and initialOpportunities actions', () => {
      const mockDispatch = jest.fn();
      Actions.getInitialOpportunities()(mockDispatch, getBasicState);
      expect(mockDispatch).toHaveBeenCalledWith({type: 'START_LOADING_OPPORTUNITIES'});
      return moxiosWait(() => {
        let request = moxios.requests.mostRecent();
        request.respondWith({
          status: 200,
          headers: {
            link: `</>; rel="next"`
          },
          response: [
            { id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
            { id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false }
          ]
        }).then(() => {
          expect(mockDispatch).toHaveBeenCalledWith({type: 'ADD_OPPORTUNITIES', payload: {
            items: [
              { id: 1, firstName: 'Fred', lastName: 'Flintstone', dismissed: false},
              { id: 2, firstName: 'Wilma', lastName: 'Flintstone', dismissed: false }
            ], nextUrl : '/'
          }});
      });
    });
  });

  it('dispatches startDismissingOpportunity and dismissedOpportunity actions', () => {
    const mockDispatch = jest.fn();
    const plannerOverride = {
      id: '10',
      plannable_type: 'assignment',
      dismissed: true
    };
    Actions.dismissOpportunity("6", plannerOverride)(mockDispatch, getBasicState);
    expect(mockDispatch).toHaveBeenCalledWith({"payload": "6", "type": "START_DISMISSING_OPPORTUNITY"});
    return moxiosWait(() => {
      let request = moxios.requests.mostRecent();
      request.respondWith({
        status: 201,
        response: [
          { id: 1, firstName: 'Fred', lastName: 'Flintstone' },
          { id: 2, firstName: 'Wilma', lastName: 'Flintstone' }
        ]
      }).then(() => {
        expect(mockDispatch).toHaveBeenCalledWith({type: 'DISMISSED_OPPORTUNITY', payload: [
          { id: 1, firstName: 'Fred', lastName: 'Flintstone' },
          { id: 2, firstName: 'Wilma', lastName: 'Flintstone' }
        ]});
      });
    });
  });

  it('dispatches startDismissingOpportunity and dismissedOpportunity actions when given override', () => {
    const mockDispatch = jest.fn();
    Actions.dismissOpportunity("6", {id: "6"})(mockDispatch, getBasicState);
    expect(mockDispatch).toHaveBeenCalledWith({"payload": "6", "type": "START_DISMISSING_OPPORTUNITY"});
    return moxiosWait(() => {
      let request = moxios.requests.mostRecent();
      request.respondWith({
        status: 201,
        response: [
          { id: 1, firstName: 'Fred', lastName: 'Flintstone' },
          { id: 2, firstName: 'Wilma', lastName: 'Flintstone' }
        ]
      }).then(() => {
        expect(mockDispatch).toHaveBeenCalledWith({type: 'DISMISSED_OPPORTUNITY', payload: [
          { id: 1, firstName: 'Fred', lastName: 'Flintstone' },
          { id: 2, firstName: 'Wilma', lastName: 'Flintstone' }
        ]});
      });
    });
  });

  it('makes correct request for dismissedOpportunity for existing override', () => {
    const plannerOverride = {
      id: '10',
      plannable_type: 'assignment',
      dismissed: true
    };
    Actions.dismissOpportunity('6', plannerOverride)(() => {});
    return moxiosWait((request) => {
      expect(request.config.method).toBe('put');
      expect(request.url).toBe('api/v1/planner/overrides/10');
      expect(JSON.parse(request.config.data)).toMatchObject(plannerOverride);
    });
  });

  it('makes correct request for dismissedOpportunity for new override', () => {
    const plannerOverride = {
      plannable_id: '10',
      dismissed: true,
      plannable_type: 'assignment'
    };
    Actions.dismissOpportunity('10', plannerOverride)(() => {});
    return moxiosWait((request) => {
      expect(request.config.method).toBe('post');
      expect(request.url).toBe('api/v1/planner/overrides');
      expect(JSON.parse(request.config.data)).toMatchObject(plannerOverride);
    });
  });

  it('calls the alert function when a failure occurs', (done) => {
    const mockDispatch = jest.fn();
    const fakeAlert = jest.fn();
    alertInitialize({
      visualErrorCallback: fakeAlert
    });
    Actions.getInitialOpportunities()(mockDispatch, getBasicState);
    moxios.wait(() => {
      let request = moxios.requests.mostRecent();
      request.respondWith({
        status: 500,
      }).then(() => {
        expect(fakeAlert).toHaveBeenCalled();
        done();
      });
    });
  });
});

  describe('savePlannerItem', () => {
    it('dispatches saving and saved actions', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data'};
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState);
      expect(isPromise(savePromise)).toBe(true);
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVING_PLANNER_ITEM', payload: {item: plannerItem, isNewItem: true}});
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVED_PLANNER_ITEM', payload: savePromise});
    });

    it('sets isNewItem to false if the item id exists', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data', id: '42'};
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState);
      expect(isPromise(savePromise)).toBe(true);
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVING_PLANNER_ITEM', payload: {item: plannerItem, isNewItem: false}});
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVED_PLANNER_ITEM', payload: savePromise});
    });

    it('sends transformed data in the request', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data'};
      Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState);
      return moxiosWait(request => {
        expect(JSON.parse(request.config.data)).toMatchObject({some: 'data', transformedToApi: true});
      });
    });

    it('resolves the promise with transformed response data', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data'};
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState);
      return moxiosRespond(
        { some: 'response data' },
        savePromise
      ).then((result) => {
        expect(result).toMatchObject({
          item: {some: 'response data', transformedToInternal: true},
          isNewItem: true,
        });
      });
    });

    it('does a post if the planner item is new (no id)', () => {
      const plannerItem = {some: 'data'};
      Actions.savePlannerItem(plannerItem)(() => {});
      return moxiosWait((request) => {
        expect(request.config.method).toBe('post');
        expect(request.url).toBe('api/v1/planner_notes');
        expect(JSON.parse(request.config.data)).toMatchObject({some: 'data', transformedToApi: true});
      });
    });

    it('does set default time of 11:59 pm for planner date', () => {
      const plannerItem = {date: moment('2017-06-22T10:05:54').tz("Atlantic/Azores").toISOString()};
      Actions.savePlannerItem(plannerItem)(() => {});
      return moxiosWait((request) => {
        expect(request.config.method).toBe('post');
        expect(request.url).toBe('api/v1/planner_notes');
        expect(JSON.parse(request.config.data).transformedToApi).toBeTruthy();
        expect(moment(JSON.parse(request.config.data).date).tz("Atlantic/Azores").toISOString()).toBe(moment('2017-06-22T23:59:59').tz("Atlantic/Azores").toISOString());
      });
    });

    it('does a put if the planner item exists (has id)', () => {
      const plannerItem = {id: '42', some: 'data'};
      Actions.savePlannerItem(plannerItem, )(() => {});
      return moxiosWait((request) => {
        expect(request.config.method).toBe('put');
        expect(request.url).toBe('api/v1/planner_notes/42');
        expect(JSON.parse(request.config.data)).toMatchObject({id: '42', some: 'data', transformedToApi: true});
      });
    });

    it('calls the alert function when a failure occurs', () => {
      const fakeAlert = jest.fn();
      const mockDispatch = jest.fn();
      alertInitialize({
        visualErrorCallback: fakeAlert
      });

      const plannerItem = {some: 'data'};
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState);
      return moxiosRespond(
        { some: 'response data' },
        savePromise,
        { status: 500 }
      ).then((result) => {
        expect(fakeAlert).toHaveBeenCalled();
      });
    });

    it('saves and restores the override data', () => {
      const mockDispatch = jest.fn();
      // a planner item with override data
      const plannerItem = {some: 'data', id: '42', overrideId: '17', completed: true};
      const savePromise = Actions.savePlannerItem(plannerItem)(mockDispatch, getBasicState);
      return moxiosRespond(
        {some: 'data', id: '42'}, // notice the response has no override data
        savePromise,
        {status: 200}
      ).then(result => {
        expect(result).toMatchObject({  // yet the resolved item does have override data
          item: {
            some: 'data',
            id: '42',
            overrideId: '17',
            completed: true,
            show: true,
            transformedToInternal: true
          },
          isNewItem: false,
        });
      });
    });
  });

  describe('deletePlannerItem', () => {
    it('dispatches deleting and deleted actions', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data'};
      const deletePromise = Actions.deletePlannerItem(plannerItem)(mockDispatch, getBasicState);
      expect(isPromise(deletePromise)).toBe(true);
      expect(mockDispatch).toHaveBeenCalledWith({type: 'DELETING_PLANNER_ITEM', payload: plannerItem});
      expect(mockDispatch).toHaveBeenCalledWith({type: 'DELETED_PLANNER_ITEM', payload: deletePromise});
    });

    it('sends a delete request for the item id', () => {
      const plannerItem = {id: '42', some: 'data'};
      Actions.deletePlannerItem(plannerItem, )(() => {});
      return moxiosWait((request) => {
        expect(request.config.method).toBe('delete');
        expect(request.url).toBe('api/v1/planner_notes/42');
      });
    });

    it('resolves the promise with transformed response data', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data'};
      const deletePromise = Actions.deletePlannerItem(plannerItem)(mockDispatch, getBasicState);
      return moxiosRespond(
        { some: 'response data' },
        deletePromise
      ).then((result) => {
        expect(result).toMatchObject({some: 'response data', transformedToInternal: true});
      });
    });

    it('calls the alert function when a failure occurs', () => {
      const fakeAlert = jest.fn();
      const mockDispatch = jest.fn();
      alertInitialize({
        visualErrorCallback: fakeAlert
      });

      const plannerItem = { some: 'data' };
      const deletePromise = Actions.deletePlannerItem(plannerItem)(mockDispatch, getBasicState);
      return moxiosRespond(
        { some: 'response data' },
        deletePromise,
        { status: 500 }
      ).then((result) => {
        expect(fakeAlert).toHaveBeenCalled();
      });
    });
  });

  describe('togglePlannerItemCompletion', () => {
    it('dispatches saving and saved actions', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data'};
      const savingItem = {...plannerItem, show: true, toggleAPIPending: true};
      const savePromise = Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState);
      expect(isPromise(savePromise)).toBe(true);
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVED_PLANNER_ITEM', payload: {item: savingItem, isNewItem: false}});
      expect(mockDispatch).toHaveBeenCalledWith({type: 'SAVED_PLANNER_ITEM', payload: savePromise});
    });

    it ('updates marked_complete and sends override data in the request', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data', marked_complete: null};
      Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState);
      return moxiosWait(request => {
        expect(JSON.parse(request.config.data)).toMatchObject({marked_complete: true, transformedToApiOverride: true});
      });
    });

    it('does a post if the planner override is new (no id)', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {id: '42', some: 'data'};
      Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState);
      return moxiosWait((request) => {
        expect(request.config.method).toBe('post');
        expect(request.url).toBe('api/v1/planner/overrides');
        expect(JSON.parse(request.config.data)).toMatchObject({marked_complete: true, transformedToApiOverride: true});
      });
    });

    it('does a put if the planner override exists (has id)', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {id: '42', some: 'data', planner_override: {id: '5', marked_complete: true}};
      Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState);
      return moxiosWait((request) => {
        expect(request.config.method).toBe('put');
        expect(request.url).toBe('api/v1/planner/overrides/5');
        expect(JSON.parse(request.config.data)).toMatchObject({id: '5', marked_complete: true, transformedToApiOverride: true});
      });
    });

    it ('resolves the promise with override response data in the item', () => {
      const mockDispatch = jest.fn();
      const plannerItem = {some: 'data', planner_override: {id: 'override_id', marked_complete: true}};
      const togglePromise = Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState);
      return moxiosRespond(
        {some: 'response data', id: 'override_id', marked_complete: false },
        togglePromise
      ).then((result) => {
        expect(result).toMatchObject({
          item: {
            ...plannerItem,
            completed: false,
            overrideId: 'override_id',
            show: true,
          },
        });
      });
    });

    it('calls the alert function and resends previous override when a failure occurs', () => {
      const fakeAlert = jest.fn();
      const mockDispatch = jest.fn();
      alertInitialize({
        visualErrorCallback: fakeAlert
      });

      const plannerItem = {some: 'data', planner_override: {id: 'override_id', marked_complete: false}};
      const togglePromise = Actions.togglePlannerItemCompletion(plannerItem)(mockDispatch, getBasicState);
      return moxiosRespond(
        {some: 'response data'},
        togglePromise,
        { status: 500 }
      ).then((result) => {
        expect(fakeAlert).toHaveBeenCalled();
        expect(result).toMatchObject({
          item: { ...plannerItem}
        });
      });
    });
  });
});

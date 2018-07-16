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
import * as Actions from '../loading-actions';
import moxios from 'moxios';
import moment from 'moment-timezone';
import { moxiosWait, moxiosRespond} from '../../test-utils';
import { initialize as alertInitialize } from '../../utilities/alertUtils';

jest.mock('../../utilities/apiUtils', () => ({
  transformApiToInternalItem: jest.fn(response => ({
    ...response,
    newActivity: response.new_activity,
    transformedToInternal: true
  })),
  transformInternalToApiItem: jest.fn(internal => ({...internal, transformedToApi: true})),
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
  },
  pendingItems: {
    past: [],
    future: [],
  },
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

  describe('sendFetchRequest', () => {
    it('fetches from the specified moment if there is no next url in the loadingOptions', () => {
      const fromMoment = moment.tz('Asia/Tokyo');
      Actions.sendFetchRequest({
        fromMoment, getState: () => ({loading: {}}),
      });
      return moxiosWait(request => {
        expect(request.config.url).toBe('/api/v1/planner/items');
        expect(request.config.params.start_date).toBe(fromMoment.toISOString());
      });
    });

    it('fetches using futureNextUrl if specified', () => {
      const fromMoment = moment.tz('Asia/Tokyo');
      Actions.sendFetchRequest({
        fromMoment, getState: () => ({loading: {futureNextUrl: 'next url'}}),
      });
      return moxiosWait(request => {
        expect(request.config.url).toBe('next url');
      });
    });

    it('sends past parameters if intoThePast is specified', () => {
      const fromMoment = moment.tz('Asia/Tokyo');
      Actions.sendFetchRequest({
        fromMoment, intoThePast: true, getState: () => ({loading: {}}),
      });
      return moxiosWait(request => {
        expect(request.config.url).toBe('/api/v1/planner/items');
        expect(request.config.params.end_date).toBe(fromMoment.toISOString());
        expect(request.config.params.order).toBe('desc');
      });
    });

    it('sends pastNextUrl if intoThePast is specified', () => {
      const fromMoment = moment.tz('Asia/Tokyo');
      Actions.sendFetchRequest({
        fromMoment, intoThePast: true, getState: () => ({loading: {pastNextUrl: 'past next url'}}),
      });
      return moxiosWait(request => {
        expect(request.config.url).toBe('past next url');
      });
    });

    it('transforms the results', () => {
      const fromMoment = moment.tz('Asia/Tokyo');
      const fetchPromise = Actions.sendFetchRequest({fromMoment, getState: () => ({loading: {}})});
      return moxiosRespond([{some: 'items'}], fetchPromise).then(result => {
        expect(result).toEqual({
          response: expect.anything(),
          transformedItems: [{some: 'items', transformedToInternal: true}]});
      });
    });
  });

  describe('getPlannerItems', () => {
    it('dispatches START_LOADING_ITEMS, getFirstNewActivityDate, and starts the saga', () => {
      const mockDispatch = jest.fn();
      Actions.getPlannerItems(moment('2017-12-18'))(mockDispatch, getBasicState);
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingItems());
      expect(mockDispatch).toHaveBeenCalledWith(Actions.continueLoadingInitialItems());
      expect(mockDispatch).toHaveBeenCalledWith(Actions.peekIntoPastSaga());
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingFutureSaga());
      const getFirstNewActivityDateThunk = mockDispatch.mock.calls[2][0];
      expect(typeof getFirstNewActivityDateThunk).toBe('function');
      const mockMoment = moment();
      const newActivityPromise = getFirstNewActivityDateThunk(mockDispatch, getBasicState);
      return moxiosRespond([{dateBucketMoment: mockMoment}], newActivityPromise).then((result) => {
        expect(mockDispatch).toHaveBeenCalledWith(expect.objectContaining({
          type: 'FOUND_FIRST_NEW_ACTIVITY_DATE',
        }));
      });
    });
  });

  describe('getFirstNewActivityDate', () => {
    it('sends deep past, filter, and order parameters', () => {
      const mockDispatch = jest.fn();
      const mockMoment = moment.tz('Asia/Tokyo').startOf('day');
      Actions.getFirstNewActivityDate(mockMoment)(mockDispatch, getBasicState);
      return moxiosWait(request => {
        expect(request.config.params.filter).toBe('new_activity');
        expect(request.config.params.start_date).toBe(mockMoment.subtract(6, 'months').toISOString());
        expect(request.config.params.order).toBe('asc');
      });
    });

    it('calls the alert method when it fails to get new activity', () => {
      const fakeAlert = jest.fn();
      alertInitialize({
        visualErrorCallback: fakeAlert
      });
      const mockDispatch = jest.fn();
      const mockMoment = moment.tz('Asia/Tokyo').startOf('day');
      const promise = Actions.getFirstNewActivityDate(mockMoment)(mockDispatch, getBasicState);
      return moxiosRespond(
        { some: 'response data' },
        promise,
        { status: 500 }
      ).then((result) => {
        expect(fakeAlert).toHaveBeenCalled();
      });
    });
  });

  describe('loadFutureItems', () => {
    it('dispatches GETTING_FUTURE_ITEMS and starts the saga', () => {
      const mockDispatch = jest.fn();
      Actions.loadFutureItems()(mockDispatch, getBasicState);
      expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingFutureItems({loadMoreButtonClicked: false}));
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingFutureSaga());
    });

    it('dispatches nothing if allFutureItemsLoaded', () => {
      const mockDispatch = jest.fn();
      const state = getBasicState();
      state.loading.allFutureItemsLoaded = true;
      Actions.loadFutureItems()(mockDispatch, () => state);
      expect(mockDispatch).not.toHaveBeenCalled();
    });
  });

  describe('scrollIntoPast', () => {
    it('dispatches GETTING_PAST_ITEMS and starts the saga', () => {
      const mockDispatch = jest.fn();
      Actions.scrollIntoPast()(mockDispatch, getBasicState);
      expect(mockDispatch).toHaveBeenCalledWith(Actions.scrollIntoPastAction());
      expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingPastItems());
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingPastSaga());
    });

    it('dispatches nothing if allPastItemsLoaded', () => {
      const mockDispatch = jest.fn();
      const state = getBasicState();
      state.loading.allPastItemsLoaded = true;
      Actions.scrollIntoPast()(mockDispatch, () => state);
      expect(mockDispatch).not.toHaveBeenCalled();
    });
  });

  describe('loadPastButtonClicked', () => {
    it('dispatches GETTING_PAST_ITEMS without the scroll into past action', () => {
      const mockDispatch = jest.fn();
      Actions.loadPastButtonClicked()(mockDispatch, getBasicState);
      expect(mockDispatch).not.toHaveBeenCalledWith(Actions.scrollIntoPastAction());
      expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingPastItems());
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingPastSaga());
    });
  });

  describe('loadPastUntilNewActivity', () => {
    it('dispatches getting past items and starts the saga', () => {
      const mockDispatch = jest.fn();
      Actions.loadPastUntilNewActivity()(mockDispatch, (getBasicState));
      expect(mockDispatch).toHaveBeenCalledWith(Actions.gettingPastItems({
        seekingNewActivity: true,
      }));
      expect(mockDispatch).toHaveBeenCalledWith(Actions.startLoadingPastUntilNewActivitySaga());
    });
  });
});

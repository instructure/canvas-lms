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

import * as Actions from '../sidebar-actions';
import moxios from 'moxios';
import moment from 'moment-timezone';
import MockDate from 'mockdate';

import {transformApiToInternalItem} from '../../utilities/apiUtils';

jest.mock('../../utilities/apiUtils');
transformApiToInternalItem.mockImplementation(item => `transformed-${item.uniqueId}`);

beforeEach(() => {
  moxios.install();
  MockDate.set('2018-01-01', 'UTC');
});

afterEach(() => {
  moxios.uninstall();
  MockDate.reset();
});

function mockGetState (overrides) {
  const state = {
    sidebar: {
      items: [],
      loading: false,
      nextUrl: null,
      loaded: false,
      ...overrides,
    },
    timeZone: 'UTC',
    courses: [],
    groups: [],
  };
  return () => state;
}

describe('load items', () => {
  it('dispatches SIDEBAR_ITEMS_LOADING action initially with target moment range', () => {
    const today = moment.tz().startOf('day');
    const thunk = Actions.sidebarLoadInitialItems(today);
    const fakeDispatch = jest.fn();
    thunk(fakeDispatch, mockGetState());
    const expected = {
      type: 'SIDEBAR_ITEMS_LOADING'
    };
    expect(fakeDispatch).toHaveBeenCalledWith(expect.objectContaining(expected));
    const action = fakeDispatch.mock.calls[0][0];
    expect(action.payload.firstMoment.toISOString()).toBe(today.clone().add(-2, 'weeks').toISOString());
    expect(action.payload.lastMoment.toISOString()).toBe(today.clone().add(2, 'weeks').toISOString());
  });

  it('dispatches SIDEBAR_ITEMS_LOADED with the proper payload on success', (done) => {
    expect.hasAssertions();
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'));
    const fakeDispatch = jest.fn();
    thunk(fakeDispatch, mockGetState());
    moxios.wait(() => {
      const request = moxios.requests.mostRecent();
      request.respondWith({
        status: 200,
        headers: {
          link: '</>; rel="current"'
        },
        response: [{ uniqueId: 1 }, { uniqueId: 2 }]
      }).then(() => {
        const expected = {
          type: 'SIDEBAR_ITEMS_LOADED',
          payload: { items: ['transformed-1', 'transformed-2'], nextUrl: null }
        };
        expect(fakeDispatch).toHaveBeenCalledWith(expected);
        done();
      });
    });
  });

  it('dispatches SIDEBAR_ITEMS_LOADED with the proper url on success', (done) => {
    expect.hasAssertions();
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'));
    const fakeDispatch = jest.fn();
    thunk(fakeDispatch, mockGetState());
    moxios.wait(() => {
      const request = moxios.requests.mostRecent();
      request.respondWith({
        status: 200,
        headers: {
          link: '</>; rel="next"'
        },
        response: [{ uniqueId: 1 }, { uniqueId: 2 }]
      }).then(() => {
        const expected = {
          type: 'SIDEBAR_ITEMS_LOADED',
          payload: { items: ['transformed-1', 'transformed-2'], nextUrl: '/' }
        };
        expect(fakeDispatch).toHaveBeenCalledWith(expected);
        done();
      });
    });
  });

  it('dispatches SIDEBAR_ALL_ITEMS_LOADED when initial load gets them all', (done) => {
    expect.hasAssertions();
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'));
    const fakeDispatch = jest.fn();
    thunk(fakeDispatch, mockGetState());
    moxios.wait(() => {
      const request = moxios.requests.mostRecent();
      request.respondWith({
        status: 200,
        headers: {
        },
        response: [{ uniqueId: 1 }, { uniqueId: 2 }]
      }).then(() => {
        const expected = {
          type: 'SIDEBAR_ITEMS_LOADED',
          payload: { items: ['transformed-1', 'transformed-2'], nextUrl: null }
        };
        expect(fakeDispatch).toHaveBeenCalledWith(expected);
        expect(fakeDispatch).toHaveBeenCalledWith({type: 'SIDEBAR_ALL_ITEMS_LOADED'});
        done();
      });
    });
  });


  it('dispatches SIDEBAR_ITEMS_LOADING_FAILED on failure', (done) => {
    expect.hasAssertions();
    const thunk = Actions.sidebarLoadInitialItems(moment().startOf('day'));
    const fakeDispatch = jest.fn();
    thunk(fakeDispatch, mockGetState());
    moxios.wait(() => {
      const request = moxios.requests.mostRecent();
      request.respondWith({
        status: 500,
        response: { error: 'Something terrible' }
      }).then(() => {
        expect(fakeDispatch).toHaveBeenCalledWith(expect.objectContaining(
          {type: 'SIDEBAR_ITEMS_LOADING_FAILED', error: true}));
        done();
      });
    });
  });
});

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

import moment from 'moment-timezone';
import { select, call, put } from 'redux-saga/effects';
import { gotItemsError, sendFetchRequest } from '../../actions/loading-actions';
import { loadPastUntilNewActivitySaga, loadPastSaga, loadFutureSaga } from '../sagas';
import {
  mergeFutureItems, mergePastItems, mergePastItemsForNewActivity
} from '../saga-actions';

function initialState (overrides = {}) {
  return {loading: {seekingNewActivity: true}, days: [], timeZone: 'Asia/Tokyo', ...overrides};
}

function setupLoadingPastUntilNewActivitySaga () {
  const generator = loadPastUntilNewActivitySaga();
  generator.next();
  generator.next(initialState());
  return generator;
}

describe('loadPastUntilNewActivitySaga', () => {
  it('sends a fetch request for past items', () => {
    const generator = loadPastUntilNewActivitySaga();
    expect(generator.next().value).toEqual(select());
    const currentState = initialState();
    const startOfDay = moment.tz(currentState.timeZone).startOf('day');
    expect(generator.next(currentState).value).toEqual(call(sendFetchRequest, {
      getState: expect.any(Function),
      fromMoment: startOfDay,
      intoThePast: true,
    }));
  });

  it('an iteration calls sendFetchRequest, calls the action creator, puts the thunk, and quits', () => {
    const generator = setupLoadingPastUntilNewActivitySaga();
    expect(generator.next({transformedItems: 'some items', response: 'some response'}).value)
      .toEqual(call(mergePastItemsForNewActivity, 'some items', 'some response'));
    expect(generator.next('a thunk').value)
      .toEqual(put('a thunk'));
    expect(generator.next(true).done).toBeTruthy();
  });

  it('loops when the thunk returns false', () => {
    const generator = setupLoadingPastUntilNewActivitySaga();
    generator.next('fetch result');
    generator.next('a thunk');
    const nextIteration = generator.next(false);
    expect(nextIteration.done).toBeFalsy();
    expect(nextIteration.value).toEqual(select());
    expect(generator.next(initialState()).value)
      .toEqual(call(sendFetchRequest, expect.anything()));
  });

  it('aborts and reports if the fetch fails', () => {
    const generator = setupLoadingPastUntilNewActivitySaga();
    const expectedError = new Error('some error');
    expect(generator.throw(expectedError).value).toEqual(put(gotItemsError(expectedError)));
    expect(() => generator.next()).toThrow();
  });
});

describe('loadPastSaga', () => {
  it('uses the past methods', () => {
    const generator = loadPastSaga();
    generator.next();
    expect(generator.next(initialState()).value).toEqual(call(sendFetchRequest, {
      getState: expect.any(Function),
      fromMoment: moment.tz('Asia/Tokyo').startOf('day'),
      intoThePast: true,
    }));
    expect(generator.next({transformedItems: 'some items', response: 'response'}).value)
      .toEqual(call(mergePastItems, 'some items', 'response'));
  });

  // not doing a full sequence of tests becuase the code is shared with the above saga
});

describe('loadFutureSaga', () => {
  it('uses the future methods', () => {
    const generator = loadFutureSaga();
    generator.next();
    expect(generator.next(initialState()).value).toEqual(call(sendFetchRequest, {
      getState: expect.any(Function),
      fromMoment: moment.tz('Asia/Tokyo').startOf('day'),
      intoThePast: false,
    }));
    expect(generator.next({transformedItems: 'some items', response: 'response'}).value)
      .toEqual(call(mergeFutureItems, 'some items', 'response'));
  });

  // not doing a full sequence of tests becuase the code is shared with the above saga
});

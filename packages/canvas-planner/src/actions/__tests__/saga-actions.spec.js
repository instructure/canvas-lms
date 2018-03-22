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

import {mergeFutureItems, mergePastItems, mergePastItemsForNewActivity}
  from '../saga-actions';
import {gotPartialFutureDays, gotPartialPastDays, gotDaysSuccess} from '../loading-actions';
import {itemsToDays} from '../../utilities/daysUtils';

function getStateFn (opts = {loading: {}}) {
  return () => ({
    loading: {
      allFutureItemsLoaded: false,
      partialFutureDays: [],

      allPastItemsLoaded: false,
      partialPastDays: [],
      ...opts.loading,
    },
  });
}

function mockItem (date = '2017-12-18', opts = {}) {
  return {
    dateBucketMoment: date,
    newActivity: false,
    ...opts,
  };
}

describe('mergeFutureItems', () => {
  it('extracts and dispatches complete days and returns true', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem('2017-12-18'), mockItem('2017-12-18'), mockItem('2017-12-19')];
    const mockDays = itemsToDays(mockItems);
    const result = mergeFutureItems(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialFutureDays: mockDays}}),
    );
    expect(result).toBe(true);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialFutureDays(mockDays, 'mock response'));
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess(itemsToDays([mockItems[0], mockItems[1]]), 'mock response'));
  });

  it('does not dispatch gotDaysSuccess if there are no complete days and returns false', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem(), mockItem()];
    const result = mergeFutureItems(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialFutureDays: itemsToDays(mockItems)}}),
    );
    expect(result).toBe(false);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialFutureDays(itemsToDays(mockItems), 'mock response'));
    expect(mockDispatch).toHaveBeenCalledTimes(1);
  });

  it('extracts all days when allFutureItemsLoaded', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem(), mockItem()];
    const result = mergeFutureItems(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialFutureDays: itemsToDays(mockItems), allFutureItemsLoaded: true}})
    );
    expect(result).toBe(true);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialFutureDays(itemsToDays(mockItems), 'mock response'));
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess(itemsToDays(mockItems), 'mock response'));
  });

  it('returns true when allFutureItemsLoaded but there are no available days', () => {
    const mockDispatch = jest.fn();
    const mockItems = [];
    const result = mergeFutureItems(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialFutureDays: [], allFutureItemsLoaded: true}})
    );
    expect(result).toBe(true);
    // still want to pretend something was loaded so all the loading states get updated.
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialFutureDays([], 'mock response'));
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess([], 'mock response'));
  });
});

describe('mergePastItems', () => {
  it('extracts complete days in reverse order', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem('2017-12-17'), mockItem('2017-12-18')];
    const result = mergePastItems(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}}),
    );
    expect(result).toBe(true);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialPastDays(itemsToDays(mockItems), 'mock response'));
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess(itemsToDays([mockItems[1]]), 'mock response'));
  });

  it('extracts all days when allPastItemsLoaded', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem(), mockItem()];
    const result = mergePastItems(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems), allPastItemsLoaded: true}})
    );
    expect(result).toBe(true);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialPastDays(itemsToDays(mockItems), 'mock response'));
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess(itemsToDays(mockItems), 'mock response'));
  });

  it('returns true when allPastItemsLoaded but there are no available days', () => {
    const mockDispatch = jest.fn();
    const mockItems = [];
    const result = mergePastItems(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialPastDays: [], allPastItemsLoaded: true}})
    );
    expect(result).toBe(true);
    // still want to pretend something was loaded so all the loading states get updated.
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialPastDays([], 'mock response'));
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess([], 'mock response'));
  });
});

describe('mergePastItemsForNewActivity', () => {
  it('does not merge complete days if there is no new activity in those days', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem('2017-12-17'), mockItem('2017-12-18')];
    const result = mergePastItemsForNewActivity(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}}),
    );
    expect(result).toBe(false);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialPastDays(itemsToDays(mockItems), 'mock response'));
    expect(mockDispatch).toHaveBeenCalledTimes(1);
  });

  it('does not merge partial days even with new activity', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem('2017-12-18', {newActivity: true})];
    const result = mergePastItemsForNewActivity(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}}),
    );
    expect(result).toBe(false);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialPastDays(itemsToDays(mockItems), 'mock response'));
    expect(mockDispatch).toHaveBeenCalledTimes(1);
  });

  it('merges days if allPastItemsLoaded even if no new activity', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem('2017-12-18')];
    const result = mergePastItemsForNewActivity(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems), allPastItemsLoaded: true}}),
    );
    expect(result).toBe(true);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialPastDays(itemsToDays(mockItems), 'mock response'));
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess(itemsToDays(mockItems), 'mock response'));
  });

  it('merges complete days when they contain new activity', () => {
    const mockDispatch = jest.fn();
    const mockItems = [mockItem('2017-12-17'), mockItem('2017-12-18', {newActivity: true}), mockItem('2017-12-18')];
    const result = mergePastItemsForNewActivity(mockItems, 'mock response')(mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}}),
    );
    expect(result).toBe(true);
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialPastDays(itemsToDays(mockItems), 'mock response'));
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess(itemsToDays([mockItems[1], mockItems[2]]), 'mock response'));
  });
});

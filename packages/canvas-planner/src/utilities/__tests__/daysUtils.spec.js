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

import {
  mergeNewItemsIntoDays, mergeNewItemsIntoDaysHash, mergeDaysIntoDaysHash, mergeDaysHashes,
  itemsToDaysHash, daysToDaysHash, itemsToDays, daysToItems, mergeItems, purgeDuplicateDays,
  mergeDays, daysHashToDays, groupAndSortDayItems,
} from '../daysUtils';

function mockItem (date = '2017-12-18', opts = {}) {
  return {
    date: date,
    dateBucketMoment: date,
    title: 'aaa',
    ...opts,
  };
}

describe('mergeNewItemsIntoDays', () => {
  it('merges', () => {
    const newItems = [
      mockItem('2017-12-18', {id: 1, title: 'merged item'}),
      mockItem('2017-12-19', {id: 2, title: 'new item'}),
    ];
    const oldItems = [mockItem('2017-12-18', {id: 3, title: 'old item'})];
    const oldDays = [['2017-12-18', oldItems]];
    const result = mergeNewItemsIntoDays(oldDays, newItems);
    expect(result).toEqual([
      ['2017-12-18', [...oldItems, newItems[0]]],
      ['2017-12-19', [newItems[1]]],
    ]);
    expect(result).not.toBe(oldDays); // no mutation
  });
});

describe('mergeDays', () => {
  it('merges', () => {
    const oldDays = [
      ['2017-12-18', [mockItem('2017-12-18', {id: 1}), mockItem('2017-12-18', {id: 2})]],
      ['2017-12-19', [mockItem('2017-12-19', {id: 3})]],
    ];
    const newDays = [
      ['2017-12-18', [mockItem('2017-12-18', {id: 4})]],
    ];
    const result = mergeDays(oldDays, newDays);
    expect(result).toEqual([
      ['2017-12-18', [
        mockItem('2017-12-18', {id: 1}),
        mockItem('2017-12-18', {id: 2}),
        mockItem('2017-12-18', {id: 4}),
      ]],
      ['2017-12-19', [mockItem('2017-12-19', {id: 3})]],
    ]);
  });
});

describe('mergeDaysIntoDaysHash', () => {
  it('merges', () => {
    const oldDaysHash = {'2017-12-18': [mockItem('2017-12-18', {id: 1})]};
    const newDays = [
      ['2017-12-18', [mockItem('2017-12-18', {id: 2})]],
      ['2017-12-19', [mockItem('2017-12-19', {id: 3})]],
    ];
    const result = mergeDaysIntoDaysHash(oldDaysHash, newDays);
    expect(result).toEqual({
      '2017-12-18': [...oldDaysHash['2017-12-18'], ...newDays[0][1]],
      '2017-12-19': [...newDays[1][1]],
    });
    expect(result).not.toBe(oldDaysHash); // no mutation
  });
});

describe('mergeNewItemsIntoDaysHash', () => {
  it('merges', () => {
    const newItems = [
      mockItem('2017-12-18', {id: 1, title: 'merged item'}),
      mockItem('2017-12-19', {id: 2, title: 'new item'}),
    ];
    const oldItems = [mockItem('2017-12-18', {id: 3, title: 'old item'})];
    const oldDaysHash = {'2017-12-18': oldItems};
    const result = mergeNewItemsIntoDaysHash(oldDaysHash, newItems);
    expect(result).toEqual({
      '2017-12-18': [...oldItems, newItems[0]],
      '2017-12-19': [newItems[1]],
    });
    expect(result).not.toBe(oldDaysHash); // no mutation
  });
});

describe('mergeDaysHashes', () => {
  it('merges', () => {
    const newDaysHash = {
      '2017-12-18': [mockItem('2017-12-18', {id: 1, title: 'merged item'})],
      '2017-12-19': [mockItem('2017-12-19', {id: 2, title: 'new item'})],
    };
    const oldItems = [mockItem('2017-12-18', {id: 3, title: 'old item'})];
    const oldDaysHash = {'2017-12-18': oldItems};
    const result = mergeDaysHashes(oldDaysHash, newDaysHash);
    expect(result).toEqual({
      '2017-12-18': [...oldItems, ...newDaysHash['2017-12-18']],
      '2017-12-19': newDaysHash['2017-12-19'],
    });
    expect(result).not.toBe(oldDaysHash); // no mutation
  });
});

describe('itemsToDaysHash', () => {
  it('converts', () => {
    const newItems = [
      mockItem('2017-12-18', {id: 1}),
      mockItem('2017-12-19', {id: 2}),
      mockItem('2017-12-19', {id: 3}),
    ];
    const result = itemsToDaysHash(newItems);
    expect(result).toEqual({
      '2017-12-18': [newItems[0]],
      '2017-12-19': [newItems[1], newItems[2]],
    });
  });
});

describe('daysToDaysHash', () => {
  it('converts', () => {
    const days = [
      ['2017-12-18', [mockItem('2017-12-18', {id: 1}), mockItem('2017-12-18', {id: 2})]],
      ['2017-12-19', [mockItem('2017-12-18', {id: 3})]],
    ];
    const result = daysToDaysHash(days);
    expect(result).toEqual({
      '2017-12-18': days[0][1],
      '2017-12-19': days[1][1],
    });
  });
});

describe('daysHashToDays', () => {
  it('converts', () => {
    const days = {
      '2017-12-18': [mockItem('2017-12-18', {id: 1}), mockItem('2017-12-18', {id: 2})],
      '2017-12-20': [],
      '2017-12-19': [mockItem('2017-12-18', {id: 3})],
    };
    const result = daysHashToDays(days);
    expect(result).toEqual([
      ['2017-12-18', days['2017-12-18']],
      ['2017-12-19', days['2017-12-19']],
    ]);
  });
});

describe('itemsToDays', () => {
  it('converts', () => {
    const items = [
      mockItem('2017-12-18', {id: 1}),
      mockItem('2017-12-19', {id: 2}),
      mockItem('2017-12-19', {id: 3}),
    ];
    const result = itemsToDays(items);
    expect(result).toEqual([
      ['2017-12-18', [items[0]]],
      ['2017-12-19', [items[1], items[2]]],
    ]);
  });
});

describe('daysToItems', () => {
  it('converts', () => {
    const days = [
      ['2017-12-18', [mockItem('2017-12-18', {id: 1})]],
      ['2017-12-19', [mockItem('2017-12-19', {id: 2})]],
    ];
    const result = daysToItems(days);
    expect(result).toEqual([
      ...days[0][1], ...days[1][1],
    ]);
  });
});

describe('mergeItems', () => {
  it('merges', () => {
    const oldItems = [
      mockItem('2017-12-18', {id: 1, title: 'to be replaced'}),
      mockItem('2017-12-18', {id: 2}),
    ];
    const newItems = [
      mockItem('2017-12-18', {id: 1, title: 'replacement'}),
      mockItem('2017-12-19', {id: 3})];
    const result = mergeItems(oldItems, newItems);
    expect(result).toEqual([newItems[0], oldItems[1], newItems[1]]);
    expect(result).not.toBe(oldItems); // no mutation
  });
});

describe('purgeDuplicateDays', () => {
  it('purges', () => {
    const oldDays = [
      ['2017-12-18', [mockItem('2017-12-18', {id: 1})]],
      ['2017-12-19', [mockItem('2017-12-18', {id: 2})]],
    ];
    const newDays = [
      ['2017-12-18', []],
    ];
    const result = purgeDuplicateDays(oldDays, newDays);
    expect(result).toEqual([oldDays[1]]);
    expect(result).not.toBe(oldDays); // no mutation
  });
});

describe('groupAndSortDayItems', () => {
  it('groups and sorts courses by title with ToDos at end', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {id: '1'}),
      mockItem('2017-12-05T11:00:00Z', {id: '2', context: {type: 'Course', id: '1', title: 'ZZZ Course'}}),
      mockItem('2017-12-05T11:00:00Z', {id: '3', context: {type: 'Course', id: '2', title: 'AAA Course'}}),
      mockItem('2017-12-05T11:00:00Z', {id: '4', context: {type: 'Course', id: '1', title: 'ZZZ Course'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {id: '3'}, {id: '2'}, {id: '4'}, {id: '1'}
    ]);
  });

  it('sorts by context type+id if missing title', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {id: '1'}),
      mockItem('2017-12-05T11:00:00Z', {id: '2', context: {type: 'Course', id: '1'}}),
      mockItem('2017-12-05T11:00:00Z', {id: '3', context: {type: 'Course', id: '2'}}),
      mockItem('2017-12-05T11:00:00Z', {id: '4', context: {type: 'Course', id: '1'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {id: '2'}, {id: '4'}, {id: '3'}, {id: '1'}
    ]);
  });

  it('sorts items with same time by title', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {id: '1'}),
      mockItem('2017-12-05T11:00:00Z', {id: '2', title: 'zzz', context: {type: 'Course', id: '1', title: 'Math'}}),
      mockItem('2017-12-05T11:00:00Z', {id: '3', context: {type: 'Course', id: '2', title: 'English'}}),
      mockItem('2017-12-05T11:00:00Z', {id: '4', title: 'aaa', context: {type: 'Course', id: '1', title: 'Math'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {id: '3'}, {id: '4'}, {id: '2'}, {id: '1'}
    ]);
  });

  it('sorts items with same time by title with numbers', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {id: '1', title: 'x 1'}),
      mockItem('2017-12-05T11:00:00Z', {id: '3', title: 'x 21'}),
      mockItem('2017-12-05T11:00:00Z', {id: '2', title: 'x 3'}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {id: '1'}, {id: '2'}, {id: '3'}
    ]);
  });

  it('sorts items by time', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {id: '1'}),
      mockItem('2017-12-05T12:00:00Z', {id: '2', context: {type: 'Course', id: '1', title: 'Math'}}),
      mockItem('2017-12-05T11:00:00Z', {id: '3', context: {type: 'Course', id: '2', title: 'English'}}),
      mockItem('2017-12-05T11:00:00Z', {id: '4', context: {type: 'Course', id: '1', title: 'Math'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {id: '3'}, {id: '4'}, {id: '2'}, {id: '1'}
    ]);
  });

});

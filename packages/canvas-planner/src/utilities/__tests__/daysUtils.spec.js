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

import {
  mergeNewItemsIntoDays, mergeNewItemsIntoDaysHash, mergeDaysIntoDaysHash, mergeDaysHashes,
  itemsToDaysHash, daysToDaysHash, itemsToDays, daysToItems, mergeItems, purgeDuplicateDays,
  mergeDays, daysHashToDays, groupAndSortDayItems, deleteItemFromDays,
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
      mockItem('2017-12-18', {uniqueId: 1, title: 'bbb merged item'}),
      mockItem('2017-12-19', {uniqueId: 2, title: 'ccc new item'}),
    ];
    const oldItems = [mockItem('2017-12-18', {uniqueId: 3, title: 'aaa old item'})];
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
      ['2017-12-18', [mockItem('2017-12-18', {uniqueId: 1}), mockItem('2017-12-18', {uniqueId: 2})]],
      ['2017-12-19', [mockItem('2017-12-19', {uniqueId: 3})]],
    ];
    const newDays = [
      ['2017-12-18', [mockItem('2017-12-18', {uniqueId: 4})]],
    ];
    const result = mergeDays(oldDays, newDays);
    expect(result).toEqual([
      ['2017-12-18', [
        mockItem('2017-12-18', {uniqueId: 1}),
        mockItem('2017-12-18', {uniqueId: 2}),
        mockItem('2017-12-18', {uniqueId: 4}),
      ]],
      ['2017-12-19', [mockItem('2017-12-19', {uniqueId: 3})]],
    ]);
  });
});

describe('mergeDaysIntoDaysHash', () => {
  it('merges', () => {
    const oldDaysHash = {'2017-12-18': [mockItem('2017-12-18', {uniqueId: 1})]};
    const newDays = [
      ['2017-12-18', [mockItem('2017-12-18', {uniqueId: 2})]],
      ['2017-12-19', [mockItem('2017-12-19', {uniqueId: 3})]],
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
      mockItem('2017-12-18', {uniqueId: 1, title: 'bbb merged item'}),
      mockItem('2017-12-19', {uniqueId: 2, title: 'ccc new item'}),
    ];
    const oldItems = [mockItem('2017-12-18', {uniqueId: 3, title: 'aaa old item'})];
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
      '2017-12-18': [mockItem('2017-12-18', {uniqueId: 1, title: 'aaa merged item'})],
      '2017-12-19': [mockItem('2017-12-19', {uniqueId: 2, title: 'bbb new item'})],
    };
    const otherItems = [
      // intentionally out of order to test that they didn't get sorted unnecessarily.
      mockItem('2017-12-17', {uniqueId: 11, title: 'zzz'}, {uniqueId: 10, title: 'yyy'}),
    ];

    const oldItems = [
      mockItem('2017-12-18', {uniqueId: 3, title: 'ccc old item'})
    ];
    const oldDaysHash = {'2017-12-17': otherItems, '2017-12-18': oldItems};
    const result = mergeDaysHashes(oldDaysHash, newDaysHash);
    expect(result).toEqual({
      '2017-12-17': otherItems, // still out of order because it should assume they were already sorted
      '2017-12-18': [...newDaysHash['2017-12-18'], ...oldItems],
      '2017-12-19': newDaysHash['2017-12-19'],
    });
    expect(result).not.toBe(oldDaysHash); // no mutation
  });
});

describe('itemsToDaysHash', () => {
  it('converts', () => {
    const newItems = [
      mockItem('2017-12-18', {uniqueId: 1}),
      mockItem('2017-12-19', {uniqueId: 2}),
      mockItem('2017-12-19', {uniqueId: 3}),
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
      ['2017-12-18', [mockItem('2017-12-18', {uniqueId: 1}), mockItem('2017-12-18', {uniqueId: 2})]],
      ['2017-12-19', [mockItem('2017-12-18', {uniqueId: 3})]],
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
      '2017-12-18': [mockItem('2017-12-18', {uniqueId: 1}), mockItem('2017-12-18', {uniqueId: 2})],
      '2017-12-20': [],
      '2017-12-19': [mockItem('2017-12-18', {uniqueId: 3})],
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
      mockItem('2017-12-18', {uniqueId: 1}),
      mockItem('2017-12-19', {uniqueId: 2}),
      mockItem('2017-12-19', {uniqueId: 3}),
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
      ['2017-12-18', [mockItem('2017-12-18', {uniqueId: 1})]],
      ['2017-12-19', [mockItem('2017-12-19', {uniqueId: 2})]],
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
      mockItem('2017-12-18', {uniqueId: 1, title: 'aaa to be replaced'}),
      mockItem('2017-12-18', {uniqueId: 2, title: 'bbb existing'}),
    ];
    const newItems = [
      mockItem('2017-12-18', {uniqueId: 1, title: 'ccc replacement'}),
      mockItem('2017-12-18', {uniqueId: 3, title: 'ddd new item'})];
    const result = mergeItems(oldItems, newItems);
    expect(result).toEqual([oldItems[1], newItems[0], newItems[1]]);
    expect(result).not.toBe(oldItems); // no mutation
  });
});

describe('purgeDuplicateDays', () => {
  it('purges', () => {
    const oldDays = [
      ['2017-12-18', [mockItem('2017-12-18', {uniqueId: 1})]],
      ['2017-12-19', [mockItem('2017-12-18', {uniqueId: 2})]],
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
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '1'}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '2', context: {type: 'Course', id: '1', title: 'ZZZ Course'}}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '3', context: {type: 'Course', id: '2', title: 'AAA Course'}}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '4', context: {type: 'Course', id: '1', title: 'ZZZ Course'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {uniqueId: '3'}, {uniqueId: '2'}, {uniqueId: '4'}, {uniqueId: '1'}
    ]);
  });

  it('sorts by context type+id if missing title', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '1'}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '2', context: {type: 'Course', id: '1'}}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '3', context: {type: 'Course', id: '2'}}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '4', context: {type: 'Course', id: '1'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {uniqueId: '2'}, {uniqueId: '4'}, {uniqueId: '3'}, {uniqueId: '1'}
    ]);
  });

  it('sorts items with same time by title', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '1'}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '2', title: 'zzz', context: {type: 'Course', id: '1', title: 'Math'}}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '3', context: {type: 'Course', id: '2', title: 'English'}}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '4', title: 'aaa', context: {type: 'Course', id: '1', title: 'Math'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {uniqueId: '3'}, {uniqueId: '4'}, {uniqueId: '2'}, {uniqueId: '1'}
    ]);
  });

  it('sorts items with same time by title with numbers', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '1', title: 'x 1'}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '3', title: 'x 21'}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '2', title: 'x 3'}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {uniqueId: '1'}, {uniqueId: '2'}, {uniqueId: '3'}
    ]);
  });

  it('sorts items by time, allDay events first', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '1'}),
      mockItem('2017-12-05T12:00:00Z', {uniqueId: '2', context: {type: 'Course', id: '1', title: 'Math'}}),
      mockItem('2017-12-05T12:30:00Z', {uniqueId: '1.5', context: {type: 'Course', id: '1', title: 'Math'}, allDay: true}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '3', context: {type: 'Course', id: '2', title: 'English'}}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '4', context: {type: 'Course', id: '1', title: 'Math'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {uniqueId: '3'}, {uniqueId: '1.5'}, {uniqueId: '4'}, {uniqueId: '2'}, {uniqueId: '1'}
    ]);
  });

  it('sorts originallyCompleted items last', () => {
    const items = [
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '1', context: {type: 'Course', id: '1', title: 'Math'}, originallyCompleted: true}),
      mockItem('2017-12-05T12:00:00Z', {uniqueId: '2', context: {type: 'Course', id: '1', title: 'Math'}}),
      mockItem('2017-12-05T12:30:00Z', {uniqueId: '3', context: {type: 'Course', id: '1', title: 'Math'}, allDay: true}),
      mockItem('2017-12-05T11:00:00Z', {uniqueId: '4', context: {type: 'Course', id: '1', title: 'Math'}}),
    ];
    const result = groupAndSortDayItems(items);
    expect(result).toMatchObject([
      {uniqueId: '3'}, {uniqueId: '4'}, {uniqueId: '2'}, {uniqueId: '1'}
    ]);
  });
});

describe('deleteItemFromDays', () => {
  it('deletes an existing item and returns new arrays', () => {
    const days = [
      ['2018-01-01', [{uniqueId: 1}, {uniqueId: 2}]],
      ['2018-01-02', [{uniqueId: 3}, {uniqueId: 4}]],
    ];
    const newDays = deleteItemFromDays(days, {uniqueId: 3});
    expect(newDays).toMatchSnapshot();
    expect(newDays).not.toBe(days);
    expect(newDays[1]).not.toBe(days[1]);
  });

  it('returns days if item does not exist', () => {
    const days = [
      ['2018-01-01', [{uniqueId: 1}, {uniqueId: 2}]],
      ['2018-01-02', [{uniqueId: 3}, {uniqueId: 4}]],
    ];
    const newDays = deleteItemFromDays(days, {uniqueId: 0});
    expect(newDays).toMatchSnapshot(); // should be unchanged and match above days
    expect(newDays).toBe(days);
  });

  it('deletes the day if it is empty', () => {
    const days = [
      ['2018-01-01', [{uniqueId: 1}, {uniqueId: 2}]],
      ['2018-01-02', [{uniqueId: 3}]],
      ['2018-01-02', [{uniqueId: 4}]],
    ];
    const newDays = deleteItemFromDays(days, {uniqueId: 3});
    expect(newDays).toMatchSnapshot();
    expect(newDays).not.toBe(days);
  });
});

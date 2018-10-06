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

import _ from 'lodash';
import { formatDayKey } from './dateUtils';

export function mergeNewItemsIntoDays (days, newItems) {
  const daysHash = daysToDaysHash(days);
  const mergedDaysHash = mergeNewItemsIntoDaysHash(daysHash, newItems);
  return daysHashToDays(mergedDaysHash);
}

export function mergeNewItemsIntoDaysHash (daysHash, newItems) {
  const newDaysHash = itemsToDaysHash(newItems);
  const mergedDaysHash = mergeDaysHashes(daysHash, newDaysHash);
  return mergedDaysHash;
}

export function mergeDaysIntoDaysHash (oldDaysHash, newDays) {
  return mergeDaysHashes(oldDaysHash, daysToDaysHash(newDays));
}

export function mergeDays (oldDays, newDays) {
  const oldDaysHash = daysToDaysHash(oldDays);
  const newDaysHash = daysToDaysHash(newDays);
  const mergedDaysHash = mergeDaysHashes(oldDaysHash, newDaysHash);
  return daysHashToDays(mergedDaysHash);
}

export function mergeDaysHashes (oldDaysHash, newDaysHash) {
  oldDaysHash = {...oldDaysHash};
  const mergedDaysHash = _.mergeWith(oldDaysHash, newDaysHash, (oldDayItems, newDayItems) => {
    if (oldDayItems == null) oldDayItems = [];
    // this is only called when necessary to merge new items into old items.
    // that way we avoid sorting items that have already been sorted.
    return mergeItems(oldDayItems, newDayItems);
  });
  return mergedDaysHash;
}

export function itemsToDaysHash (items) {
  return _.groupBy(items, item => formatDayKey(item.dateBucketMoment));
}

export function daysToDaysHash (days) {
  return _.fromPairs(days);
}

export function daysHashToDays (days) {
  return _.chain(days)
    .toPairs()
    .filter(d => d[1] && d[1].length) // discard any day with no items
    .sortBy(_.head)
    .value();
}

export function itemsToDays (items) {
  return daysHashToDays(itemsToDaysHash(items));
}

export function daysToItems (days) {
  return days.reduce((memo, day) => [...memo, ...day[1]], []);
}

export function mergeItems(oldItems, newItems) {
  const newItemsMap = new Map(newItems.map(item => [item.uniqueId, item]));
  const oldItemsMerged = oldItems.map(oldItem => {
    const newItem = newItemsMap.get(oldItem.uniqueId);
    if (newItem) {
      newItemsMap.delete(newItem.uniqueId);
      return newItem;
    } else {
      return oldItem;
    }
  });
  const resultingItems = oldItemsMerged.concat([...newItemsMap.values()]);
  // mergeItems is only called as needed to merge new items into old items,
  // so sorting here is ok and won't wind up sorting every day on every merge.
  return groupAndSortDayItems(resultingItems);
}

// returns {dayIndex, itemIndex, item}. Both indexes are -1 and item is undefined if the item isn't found.
export function findItemInDays (days, uniqueId) {
  let dayIndex = -1;
  let itemIndex = -1;
  if (uniqueId !== undefined) {
    dayIndex = days.findIndex(day => {
      const items = day[1];
      itemIndex = items.findIndex(itemToCheck => itemToCheck.uniqueId === uniqueId);
      return itemIndex !== -1;
    });
  }
  const item = dayIndex !== -1 ? days[dayIndex][1][itemIndex] : undefined;
  return {dayIndex, itemIndex, item};
}

export function deleteItemFromDaysAt (days, dayIndex, itemIndex) {
  const oldItems = days[dayIndex][1];
  const newItems = oldItems.filter((_, index) => index !== itemIndex);
  if (newItems.length === 0) {
    return days.filter((_, index) => index !== dayIndex);
  } else {
    const newDay = days[dayIndex].slice(0); // copy
    newDay[1] = newItems;
    const newDays = days.slice(0);
    newDays[dayIndex] = newDay;
    return newDays;
  }
}

export function deleteItemFromDays (days, doomedItem) {
  const {dayIndex, itemIndex} = findItemInDays(days, doomedItem.uniqueId);
  if (dayIndex === -1 || itemIndex === -1) return days;
  return deleteItemFromDaysAt(days, dayIndex, itemIndex);
}

export function purgeDuplicateDays (oldDays, newDays) {
  const purgedDaysHash = daysToDaysHash(oldDays);
  newDays.forEach(day => { delete purgedDaysHash[day[0]]; });
  return daysHashToDays(purgedDaysHash);
}

// sort the items:
// First by grouping (alpha by course or group title, followed by the Notes (aka To Dos)
// Then by due-time for each item w/in the grouping.
export function groupAndSortDayItems (items) {
  return items.sort(orderItems);
}

// ----- grouping and sorting helpers -----
const cmpopts = {numeric: true};
const locale =(window.ENV && window.ENV.MOMENT_LOCALE) || 'en';

// order items by their grouping
function getItemGroupTitle(item) {
  if (item.context && item.context.id) {  // edited items have an empty context, so look for the id too
    return item.context.title || `${item.context.type}${item.context.id}`;
  }
  return 'Notes';
}

function orderItemsByGrouping (a, b) {
  let namea = getItemGroupTitle(a);
  let nameb = getItemGroupTitle(b);
  if (namea.localeCompare(nameb, locale, cmpopts) === 0) return 0;
  if (namea === 'Notes') return 1;
  if (nameb === 'Notes') return -1;
  return namea.localeCompare(nameb, locale, cmpopts);
}

// order items by time, then title
export function orderItemsByTimeAndTitle (a, b) {
  // completed items are grouped at the bottom
  if (a.originallyCompleted && !b.originallyCompleted) return 1;
  if (!a.originallyCompleted && b.originallyCompleted) return -1;
  // all day items are grouped at the top
  if (a.allDay && !b.allDay) return -1;
  if (!a.allDay && b.allDay) return 1;
  // the rest are sorted by time, then title
  if (a.date.valueOf() === b.date.valueOf()) {
    return a.title.localeCompare(b.title, locale, cmpopts);
  }
  return a.date < b.date ? -1 : 1;
}

// order items
function orderItems (a, b) {
  let order = orderItemsByGrouping(a, b);
  if (order === 0) {
    order = orderItemsByTimeAndTitle(a, b);
  }
  return order;
}

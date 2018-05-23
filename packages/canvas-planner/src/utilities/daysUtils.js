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
  const newItemsMap = new Map(newItems.map(item => [item.id, item]));
  const oldItemsMerged = oldItems.map(oldItem => {
    const newItem = newItemsMap.get(oldItem.id);
    if (newItem) {
      newItemsMap.delete(newItem.id);
      return newItem;
    } else {
      return oldItem;
    }
  });
  return oldItemsMerged.concat([...newItemsMap.values()]);
}

export function purgeDuplicateDays (oldDays, newDays) {
  const purgedDaysHash = daysToDaysHash(oldDays);
  newDays.forEach(day => { delete purgedDaysHash[day[0]]; });
  return daysHashToDays(purgedDaysHash);
}

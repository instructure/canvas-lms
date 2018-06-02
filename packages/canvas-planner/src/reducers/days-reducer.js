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

import { handleActions } from 'redux-actions';
import { formatDayKey } from '../utilities/dateUtils';
import { findPlannerItemById } from '../utilities/storeUtils';
import { daysToDaysHash, daysHashToDays, mergeDaysIntoDaysHash, itemsToDays } from '../utilities/daysUtils';

function savedPlannerItem (state, action) {
  if (action.error) return state;
  const newPlannerItem = action.payload.item;
  const oldPlannerItem = newPlannerItem.id ? findPlannerItemById(state, newPlannerItem.id) : null;
  let newState = state;
  // if changing days, then we need to delete the old item from its current day
  if (oldPlannerItem && !oldPlannerItem.dateBucketMoment.isSame(newPlannerItem.dateBucketMoment)) {
    newState = _deletePlannerItem(newState, oldPlannerItem);
  }
  return gotDaysSuccess(newState, itemsToDays([newPlannerItem]));
}

function deletedPlannerItem (state, action) {
  if (action.error) return state;
  return _deletePlannerItem(state, action.payload);
}

function _deletePlannerItem(state, doomedPlannerItem) {
  const plannerDateString = formatDayKey(doomedPlannerItem.dateBucketMoment);
  const keyedState = new Map(state);
  const existingDay = keyedState.get(plannerDateString);
  if (existingDay == null) return state;

  const newDay = existingDay.filter(item => item.id !== doomedPlannerItem.id);
  if (newDay.length) {
    keyedState.set(plannerDateString, newDay);
  } else {
    keyedState.delete(plannerDateString);
  }
  return [...keyedState.entries()];
}


function gotDaysSuccess (state, days) {
  const oldDaysHash = daysToDaysHash(state);
  const mergedDaysHash = mergeDaysIntoDaysHash(oldDaysHash, days);
  return daysHashToDays(mergedDaysHash);
}

export default handleActions({
  GOT_DAYS_SUCCESS: (state, action) => gotDaysSuccess(state, action.payload.internalDays),
  SAVED_PLANNER_ITEM: savedPlannerItem,
  DELETED_PLANNER_ITEM: deletedPlannerItem,
}, []);

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

import * as LA from './loading-actions.js';
import {anyNewActivityDays} from '../utilities/statusUtils';
import {itemsToDays} from '../utilities/daysUtils';

export const mergeFutureItems = (newFutureItems, response) => (dispatch, getState) => {
  dispatch(LA.gotPartialFutureDays(itemsToDays(newFutureItems), response));
  const state = getState();
  const completeDays = extractCompleteDays(
    state.loading.partialFutureDays, state.loading.allFutureItemsLoaded, 'asc',
  );
  return mergeCompleteDays(completeDays, dispatch, state.loading.allFutureItemsLoaded, response);
};

export const mergePastItems = (newPastItems, response) => (dispatch, getState) => {
  dispatch(LA.gotPartialPastDays(itemsToDays(newPastItems), response));
  const state = getState();
  const completeDays = extractCompleteDays(
    state.loading.partialPastDays, state.loading.allPastItemsLoaded, 'desc',
  );
  return mergeCompleteDays(completeDays, dispatch, state.loading.allPastItemsLoaded, response);
};

export const mergePastItemsForNewActivity = (newPastItems, response) => (dispatch, getState) => {
  dispatch(LA.gotPartialPastDays(itemsToDays(newPastItems), response));
  const state = getState();
  const completeDays = extractCompleteDays(
    state.loading.partialPastDays, state.loading.allPastItemsLoaded, 'desc',
  );
  if (anyNewActivityDays(completeDays) || state.loading.allPastItemsLoaded) {
    return mergeCompleteDays(completeDays, dispatch, state.loading.allPastItemsLoaded, response);
  }
  return false;
};

function mergeCompleteDays (completeDays, dispatch, allItemsLoaded, response) {
  if (completeDays.length || allItemsLoaded) {
    dispatch(LA.gotDaysSuccess(completeDays, response));
    return true;
  }
  return false;
}

function extractCompleteDays (daysArray, everythingCompleted, direction) {
  const partialDays = daysArray.slice();
  if (direction === 'desc') partialDays.reverse();
  if (everythingCompleted) return partialDays;
  const completeDays = partialDays.slice(0, -1);
  return completeDays;
}

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
import { combineReducers } from 'redux';
import { isInMomentRange } from '../utilities/dateUtils';
import { orderItemsByTimeAndTitle } from '../utilities/daysUtils';

const items = handleActions({
  SIDEBAR_ITEMS_LOADED: (state, action) => {
    const newState = state.concat(action.payload.items);
    sortItems(newState);
    return newState;
  },
  DELETED_PLANNER_ITEM: deleteItem,
}, []);

function deleteItem (state, action) {
  const doomedIndex = state.findIndex(item => item.uniqueId === action.payload.uniqueId);
  if (doomedIndex > -1) {
    const newState = state.slice();
    newState.splice(doomedIndex, 1);
    return newState;
  }
  return state;
}

const nextUrl = handleActions({
  SIDEBAR_ITEMS_LOADED: (state, action) => action.payload.nextUrl
}, null);

const loading = handleActions({
  SIDEBAR_ITEMS_LOADING: () => true,
  SIDEBAR_ITEMS_LOADED: () => false,
  SIDEBAR_ENOUGH_ITEMS_LOADED: () => false,
  SIDEBAR_ITEMS_LOADING_FAILED: () => false
}, false);

const loaded = handleActions({
  SIDEBAR_ENOUGH_ITEMS_LOADED: () => true
}, false);

const range = handleActions({
  SIDEBAR_ITEMS_LOADING: (state, action) => {
    if (action.payload) return {...state, ...action.payload};
    else return state;
  }
}, {});

const combinedReducer = combineReducers({
  items,
  loading,
  nextUrl,
  loaded,
  range,
});

function sortItems (items) {
  return items.sort(orderItemsByTimeAndTitle);
}

function savedItemReducer (state, action) {
  if (!state) return undefined;
  if (!state.loaded || action.type !== 'SAVED_PLANNER_ITEM') return state;
  if (!action.payload.item || !action.payload.item.uniqueId) return state;

  const newItem = action.payload.item;
  let newItems = state.items.slice();
  let changed = false;
  const oldItemIndex = state.items.findIndex(item => item.uniqueId === newItem.uniqueId);
  if (oldItemIndex > -1) {
    newItems.splice(oldItemIndex, 1);
    changed = true;
  }
  if (isInMomentRange(newItem.date, state.range.firstMoment, state.range.lastMoment)) {
    newItems.push(newItem);
    sortItems(newItems);
    changed = true;
  }
  return changed ? {...state, items: newItems} : state;
}

export default function reducer (state, action) {
  let newState = savedItemReducer(state, action);
  newState = combinedReducer(newState, action);
  return newState;
}

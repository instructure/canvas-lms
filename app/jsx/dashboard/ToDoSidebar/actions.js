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

import { createActions } from 'redux-actions';
import axios from 'axios';
import parseLinkHeader from 'parse-link-header';

export const {
  itemsLoading,
  itemsLoaded,
  itemsLoadingFailed,
  itemSaving,
  itemSaved,
  itemSavingFailed,
  allItemsLoaded
} = createActions(
  'ITEMS_LOADING',
  'ITEMS_LOADED',
  'ITEMS_LOADING_FAILED',
  'ITEM_SAVING',
  'ITEM_SAVED',
  'ITEM_SAVING_FAILED',
  'ALL_ITEMS_LOADED'
);

export const loadNextItems = () => (
  (dispatch, getState) => {
    if (!getState().loaded && getState().nextUrl) {
      dispatch(itemsLoading());
      axios.get(getState().nextUrl, { params: {
        order: 'asc'
      }}).then((response) => {
        const linkHeader = parseLinkHeader(response.headers.link)
        if (linkHeader && linkHeader.next) {
          dispatch(itemsLoaded({ items: response.data, nextUrl: linkHeader.next.url }));
          dispatch(loadNextItems());
        } else {
          dispatch(allItemsLoaded())
          dispatch(itemsLoaded({ items: response.data, nextUrl: null }));
        }
      }).catch(response => dispatch(itemsLoadingFailed(response)));
    }
  }
);

export const loadInitialItems = currentMoment => (
  (dispatch) => {
    dispatch(itemsLoading());
    const firstMomentDate = currentMoment.clone().subtract(2, 'weeks');
    const lastMomentDate = currentMoment.clone().add(2, 'weeks');
    axios.get('/api/v1/planner/items', { params: {
      start_date: firstMomentDate.toISOString(),
      end_date: lastMomentDate.toISOString(),
      order: 'asc'
    }}).then((response) => {
      const linkHeader = parseLinkHeader(response.headers.link)
      if (linkHeader && linkHeader.next) {
        dispatch(itemsLoaded({ items: response.data, nextUrl: linkHeader.next.url }));
        dispatch(loadNextItems());
      } else {
        dispatch(itemsLoaded({ items: response.data, nextUrl: null }));
      }
    }).catch(response => dispatch(itemsLoadingFailed(response)));
  }
);

export const completeItem = (itemType, itemId) => (
  (dispatch, getState) => {
    dispatch(itemSaving());

    const itemToUpdate = getState().items.find(item => (
      item.plannable_id === itemId &&
      item.plannable_type === itemType
    ));
    if (itemToUpdate.planner_override) {

      const plannerOverride = itemToUpdate.planner_override;
      plannerOverride.marked_complete = true;

      return axios.put(`/api/v1/planner/overrides/${plannerOverride.id}`, {
        ...plannerOverride
      }).then(response => dispatch(itemSaved(response.data)))
        .catch(response => dispatch(itemSavingFailed(response)));
    } else {
      return axios.post('/api/v1/planner/overrides', {
        marked_complete: true,
        plannable_type: itemToUpdate.plannable_type,
        plannable_id: itemToUpdate.plannable_id
      }).then(response => dispatch(itemSaved(response.data)))
        .catch(response => dispatch(itemSavingFailed(response)));
    }
  }
)

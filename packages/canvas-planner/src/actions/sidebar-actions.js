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
import { togglePlannerItemCompletion } from '../actions';
import { transformApiToInternalItem } from '../utilities/apiUtils';

export const {
  sidebarItemsLoading,
  sidebarItemsLoaded,
  sidebarItemsLoadingFailed,
  sidebarAllItemsLoaded
} = createActions(
  'SIDEBAR_ITEMS_LOADING',
  'SIDEBAR_ITEMS_LOADED',
  'SIDEBAR_ITEMS_LOADING_FAILED',
  'SIDEBAR_ALL_ITEMS_LOADED'
);

export const sidebarLoadNextItems = () => (
  (dispatch, getState) => {
    if (!getState().sidebar.loaded && getState().sidebar.nextUrl) {
      dispatch(sidebarItemsLoading());
      axios.get(getState().sidebar.nextUrl, { params: {
        order: 'asc'
      }}).then((response) => {
        const linkHeader = parseLinkHeader(response.headers.link);
        const transformedItems = response.data.map(item => transformApiToInternalItem(
          item, getState().courses, getState().groups, getState().timeZone));
      if (linkHeader && linkHeader.next) {
          dispatch(sidebarItemsLoaded({ items: transformedItems, nextUrl: linkHeader.next.url }));
          dispatch(sidebarLoadNextItems());
        } else {
          dispatch(sidebarItemsLoaded({ items: transformedItems, nextUrl: null }));
          dispatch(sidebarAllItemsLoaded());
        }
      }).catch(response => dispatch(sidebarItemsLoadingFailed(response)));
    }
  }
);

export const sidebarLoadInitialItems = currentMoment => (
  (dispatch, getState) => {
    const firstMomentDate = currentMoment.clone().subtract(2, 'weeks');
    const lastMomentDate = currentMoment.clone().add(2, 'weeks');
    dispatch(sidebarItemsLoading({firstMoment: firstMomentDate, lastMoment: lastMomentDate}));
    axios.get('/api/v1/planner/items', { params: {
      start_date: firstMomentDate.toISOString(),
      end_date: lastMomentDate.toISOString(),
      order: 'asc'
    }}).then((response) => {
      const linkHeader = parseLinkHeader(response.headers.link);
      const transformedItems = response.data.map(item => transformApiToInternalItem(
        item, getState().courses, getState().groups, getState().timeZone));
    if (linkHeader && linkHeader.next) {
        dispatch(sidebarItemsLoaded({ items: transformedItems, nextUrl: linkHeader.next.url }));
        dispatch(sidebarLoadNextItems());
      } else {
        dispatch(sidebarItemsLoaded({ items: transformedItems, nextUrl: null }));
        dispatch(sidebarAllItemsLoaded());
      }
    }).catch(response => dispatch(sidebarItemsLoadingFailed(response)));
  }
);

export const sidebarCompleteItem = (item) => {
  return togglePlannerItemCompletion(item);
};

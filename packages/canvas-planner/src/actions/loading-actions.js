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

import { createActions, createAction } from 'redux-actions';
import axios from 'axios';
import { transformApiToInternalItem } from '../utilities/apiUtils';
import { alert } from '../utilities/alertUtils';
import formatMessage from '../format-message';
import { itemsToDays } from '../utilities/daysUtils';

export const {
  startLoadingItems,
  continueLoadingInitialItems,
  foundFirstNewActivityDate,
  gettingFutureItems,
  allFutureItemsLoaded,
  allPastItemsLoaded,
  gotItemsError,
  startLoadingPastSaga,
  startLoadingFutureSaga,
  startLoadingPastUntilNewActivitySaga,
  startLoadingGradesSaga,
  gotGradesSuccess,
  gotGradesError,
  startLoadingPastUntilTodaySaga,
  peekIntoPastSaga,
  peekedIntoPast,
} = createActions(
  'START_LOADING_ITEMS',
  'CONTINUE_LOADING_INITIAL_ITEMS',
  'FOUND_FIRST_NEW_ACTIVITY_DATE',
  'GETTING_FUTURE_ITEMS',
  'ALL_FUTURE_ITEMS_LOADED',
  'ALL_PAST_ITEMS_LOADED',
  'GOT_ITEMS_ERROR',
  'START_LOADING_PAST_SAGA',
  'START_LOADING_FUTURE_SAGA',
  'START_LOADING_PAST_UNTIL_NEW_ACTIVITY_SAGA',
  'START_LOADING_GRADES_SAGA',
  'GOT_GRADES_SUCCESS',
  'GOT_GRADES_ERROR',
  'START_LOADING_PAST_UNTIL_TODAY_SAGA',
  'PEEK_INTO_PAST_SAGA',
  'PEEKED_INTO_PAST',
);

export const gettingPastItems = createAction('GETTING_PAST_ITEMS', (opts = {seekingNewActivity: false}) => {
  return opts;
});

export const gotDaysSuccess = createAction('GOT_DAYS_SUCCESS', (newDays, response) => {
  return { internalDays: newDays, response };
});

export function gotItemsSuccess (newItems, response) {
  return gotDaysSuccess(itemsToDays(newItems), response);
}

export const gotPartialFutureDays = createAction('GOT_PARTIAL_FUTURE_DAYS', (newDays, response) => {
  return { internalDays: newDays, response };
});

export const gotPartialPastDays = createAction('GOT_PARTIAL_PAST_DAYS', (newDays, response) => {
  return { internalDays: newDays, response };
});

export function getFirstNewActivityDate (fromMoment) {
  // We are requesting ascending order and only grabbing the first item,
  // specifically so we know what the very oldest new activity is
  return (dispatch, getState) => {
    fromMoment = fromMoment.clone().subtract(6, 'months');
    return axios.get('/api/v1/planner/items', { params: {
      start_date: fromMoment.toISOString(),
      filter: 'new_activity',
      order: 'asc'
    }}).then(response => {
      if (response.data.length) {
        const first = transformApiToInternalItem(response.data[0], getState().courses, getState().groups, getState().timeZone);
        dispatch(foundFirstNewActivityDate(first.dateBucketMoment));
      }
    }).catch(() => alert(formatMessage('Failed to get new activity'), true));
  };
}

// this is the initial load
export function getPlannerItems (fromMoment) {
  return (dispatch, getState) => {

    dispatch(startLoadingItems());
    dispatch(continueLoadingInitialItems()); // a start counts as a continue for the ContinueInitialLoad animation
    dispatch(getFirstNewActivityDate(fromMoment));
    dispatch(peekIntoPastSaga());
    dispatch(startLoadingFutureSaga());
  };
}

export function loadFutureItems (opts = {loadMoreButtonClicked: false}) {
  return (dispatch, getState) => {
    if (getState().loading.allFutureItemsLoaded) return;
    dispatch(gettingFutureItems(opts));
    dispatch(startLoadingFutureSaga());
  };
}

export const scrollIntoPastAction = createAction('SCROLL_INTO_PAST');

function loadPastItems (byScrolling) {
  return (dispatch, getState) => {
    if (getState().loading.allPastItemsLoaded) return;
    if (byScrolling) dispatch(scrollIntoPastAction());
    dispatch(gettingPastItems({
      seekingNewActivity: false,
    }));
    dispatch(startLoadingPastSaga());
  };
}

export function scrollIntoPast () {
    return loadPastItems(true);
}

export function loadPastButtonClicked () {
  return loadPastItems(false);
}

export const loadPastUntilNewActivity = () => (dispatch, getState) => {
  dispatch(gettingPastItems({
    seekingNewActivity: true,
  }));
  dispatch(startLoadingPastUntilNewActivitySaga());
  return 'loadPastUntilNewActivity'; // for testing
};

export const loadPastUntilToday = () => (dispatch, getState) => {
  dispatch(gettingPastItems({
    seekingNewActivity: false,
  }));
  dispatch(startLoadingPastUntilTodaySaga());
  return 'loadPastUntilToday'; // for testing
};


export function sendFetchRequest (loadingOptions) {
  return axios.get(...fetchParams(loadingOptions))
    .then(response => handleFetchResponse(loadingOptions, response))
    // no .catch: it's up to the sagas to handle errors
  ;
}

function fetchParams (loadingOptions) {
  let timeParam = 'start_date';
  let linkField = 'futureNextUrl';
  if (loadingOptions.intoThePast) {
    timeParam = 'end_date';
    linkField = 'pastNextUrl';
  }
  const nextPageUrl = loadingOptions.getState().loading[linkField];
  if (nextPageUrl) {
    return [nextPageUrl, {}];
  } else {
    const params = {
      [timeParam]: loadingOptions.fromMoment.toISOString()
    };
    if (loadingOptions.intoThePast) {
      params.order = 'desc';
    }
    if (loadingOptions.perPage) {
      params.per_page = loadingOptions.perPage;
    }
    return [
      '/api/v1/planner/items',
      { params },
    ];
  }
}

function handleFetchResponse (loadingOptions, response) {
  const transformedItems = transformItems(loadingOptions, response.data);
  return {response, transformedItems};
}

function transformItems (loadingOptions, items) {
  return items.map(item => transformApiToInternalItem(
    item,
    loadingOptions.getState().courses,
    loadingOptions.getState().groups,
    loadingOptions.getState().timeZone,
  ));
}

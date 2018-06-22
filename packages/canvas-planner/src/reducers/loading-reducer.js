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

import { handleActions } from 'redux-actions';
import parseLinkHeader from 'parse-link-header';
import {mergeDays, purgeDuplicateDays} from '../utilities/daysUtils';
import {findNextLink} from '../utilities/apiUtils';

function loadingState (currentState, loadingState) {
  return {
    ...currentState,
    isLoading: false,
    loadingPast: false,
    loadingFuture: false,
    loadingError: undefined,
    // all other properties should retain their current values unless loadingState sets them
    ...loadingState,
  };
}

function findNextLinkFromAction (action) {
  const response = action.payload.response;
  if (response == null) return null;
  return findNextLink(response);
}

function getNextUrls (state, action) {
  const linkState = {};
  const nextLink = findNextLinkFromAction(action);

  if (state.isLoading || state.loadingFuture) {
    linkState.futureNextUrl = nextLink;
    if (nextLink == null) linkState.allFutureItemsLoaded = true;
  }
  if (state.loadingPast) {
    linkState.pastNextUrl = nextLink;
    if (nextLink == null) linkState.allPastItemsLoaded = true;
  }

  return linkState;
}

function gotDaysSuccess (state, action) {
  const newState = {seekingNewActivity: false, plannerLoaded: true};
  newState.partialPastDays = purgeDuplicateDays(state.partialPastDays, action.payload.internalDays);
  newState.partialFutureDays = purgeDuplicateDays(state.partialFutureDays, action.payload.internalDays);
  return loadingState(state, newState);
}

function gotPartialPastDays (state, action) {
  const linkState = getNextUrls(state, action);
  return {
    ...state,
    ...linkState,
    partialPastDays: mergeDays(state.partialPastDays, action.payload.internalDays)
  };
}

function gotPartialFutureDays (state, action) {
  const linkState = getNextUrls(state, action);
  return {
    ...state,
    ...linkState,
    partialFutureDays: mergeDays(state.partialFutureDays, action.payload.internalDays),
  };
}

function gotItemsError (state, action) {
  const error = action.payload.message || action.payload;
  return loadingState(state, {loadingError: error});
}

export default handleActions({
  GOT_DAYS_SUCCESS: gotDaysSuccess,
  GOT_ITEMS_ERROR: gotItemsError,
  GOT_PARTIAL_PAST_DAYS: gotPartialPastDays,
  GOT_PARTIAL_FUTURE_DAYS: gotPartialFutureDays,
  START_LOADING_OPPORTUNITIES: (state, action) => {
    return {...state, loadingOpportunities: true};
  },
  START_LOADING_ITEMS: (state, action) => {
    return loadingState(state, {isLoading: true});
  },
  GETTING_PAST_ITEMS: (state, action) => {
    return loadingState(state, {
      loadingError: state.loadingError, // don't reset error until we're successful
      loadingPast: true,
      seekingNewActivity: action.payload.seekingNewActivity
    });
  },
  PEEKED_INTO_PAST: (state, action) => {
    return loadingState(state, {
      hasSomeItems: action.payload.hasSomeItems,
      allPastItemsLoaded: !action.payload.hasSomeItems,
      isLoading: state.isLoading,
    });
  },
  GETTING_FUTURE_ITEMS: (state, action) => {
    return loadingState(state, {
      loadingError: state.loadingError, // don't reset error until we're successful
      loadingFuture: true
    });
  },
  DELETED_PLANNER_ITEM: (state, action) => {
    return loadingState(state, {hasSomeItems: false});  // because we can no longer be sure
  },
  SAVED_PLANNER_ITEM: (state, action) => {
    return loadingState(state, {hasSomeItems: true}); // even if days[] is empty, we know we have an item
  },
  ALL_FUTURE_ITEMS_LOADED: (state, action) => {
    return loadingState(state, {allFutureItemsLoaded: true});
  },
  ALL_OPPORTUNITIES_LOADED: (state, action) => {
    return {...state, loadingOpportunities: false, allOpportunitiesLoaded: true};
  },
  ALL_PAST_ITEMS_LOADED: (state, action) => {
    return loadingState(state, {allPastItemsLoaded: true});
  },
  ADD_OPPORTUNITIES: (state, action) => {
    return {...state, loadingOpportunities: false};
  },
  START_LOADING_GRADES_SAGA: (state, action) => ({
    ...state, loadingGrades: true, gradesLoadingError: null}),
  GOT_GRADES_SUCCESS: (state, action) => ({
    ...state, loadingGrades: false, gradesLoaded: true, gradesLoadingError: null}),
  GOT_GRADES_ERROR: (state, action) => ({
     ...state, loadingGrades: false, gradesLoaded: false,
     gradesLoadingError: action.payload.message}),
  
}, loadingState({}, {
  isLoading: false,
  loadingPast: false,
  loadingFuture: false,
  plannerLoaded: false,
  allPastItemsLoaded: false,
  allFutureItemsLoaded: false,
  allOpportunitiesLoaded: false,
  loadingOpportunities: false,
  futureNextUrl: null,
  pastNextUrl: null,
  seekingNewActivity: false,
  partialPastDays: [],
  partialFutureDays: [],
  hasSomeItems: false,    // set to true if the first peek into the past returns an item
                          // reset to false if an item is deleted, because we can't know
                          // if it was the last one
  loadingGrades: false,
  gradesLoaded: false,
  gradesLoadingError: null,
}));

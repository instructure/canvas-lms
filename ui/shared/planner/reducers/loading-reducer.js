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

import {handleActions} from 'redux-actions'
import {mergeDays, purgeDuplicateDays} from '../utilities/daysUtils'
import {findNextLink} from '../utilities/apiUtils'

const INITIAL_STATE = {
  isLoading: false,
  loadingPast: false,
  loadingFuture: false,
  loadingWeek: false,
  plannerLoaded: false,
  allPastItemsLoaded: false,
  allFutureItemsLoaded: false,
  allWeekItemsLoaded: false,
  allOpportunitiesLoaded: false,
  loadingOpportunities: false,
  futureNextUrl: null,
  pastNextUrl: null,
  seekingNewActivity: false,
  partialPastDays: [],
  partialFutureDays: [],
  partialWeekDays: [],
  hasSomeItems: null, // Tri-state. Initially null because we haven't checked yet.
  // Set to true if the first peek into the past returns an item.
  // Reset to false if an item is deleted, because we can't know
  // if it was the last one.
  loadingGrades: false,
  gradesLoaded: false,
  gradesLoadingError: null,
}

function loadingState(currentState, loadingState_) {
  return {
    ...currentState,
    isLoading: false,
    loadingPast: false,
    loadingFuture: false,
    loadingError: undefined,
    // all other properties should retain their current values unless loadingState sets them
    ...loadingState_,
  }
}

function findNextLinkFromAction(action) {
  const response = action.payload.response
  if (response == null) return null
  return findNextLink(response)
}

function getNextUrls(state, action) {
  const linkState = {}
  const nextLink = findNextLinkFromAction(action)

  if (state.isLoading || state.loadingFuture) {
    linkState.futureNextUrl = nextLink
    if (nextLink == null) linkState.allFutureItemsLoaded = true
  }
  if (state.loadingPast) {
    linkState.pastNextUrl = nextLink
    if (nextLink == null) linkState.allPastItemsLoaded = true
  }
  if (state.isLoading || state.loadingWeek) {
    linkState.weekNextUrl = nextLink
  }
  if (nextLink == null) linkState.allWeekItemsLoaded = true

  return linkState
}

function gotDaysSuccess(state, action) {
  const newState = {seekingNewActivity: false, plannerLoaded: true}
  newState.partialPastDays = purgeDuplicateDays(state.partialPastDays, action.payload.internalDays)
  newState.partialFutureDays = purgeDuplicateDays(
    state.partialFutureDays,
    action.payload.internalDays
  )
  newState.partialWeekDays = purgeDuplicateDays(state.partialWeekDays, action.payload.internalDays)
  return loadingState(state, newState)
}

function gotPartialPastDays(state, action) {
  const linkState = getNextUrls(state, action)
  return {
    ...state,
    ...linkState,
    partialPastDays: mergeDays(state.partialPastDays, action.payload.internalDays),
  }
}

function gotPartialFutureDays(state, action) {
  const linkState = getNextUrls(state, action)
  return {
    ...state,
    ...linkState,
    partialFutureDays: mergeDays(state.partialFutureDays, action.payload.internalDays),
  }
}

function gotPartialWeekDays(state, action) {
  const linkState = getNextUrls(state, action)
  const pwd = mergeDays(state.partialWeekDays, action.payload.internalDays)
  return {
    ...state,
    ...linkState,
    partialWeekDays: pwd,
  }
}

function gotItemsError(state, action) {
  const error = action.payload.message || action.payload
  return loadingState(state, {loadingError: error})
}

export default handleActions(
  {
    GOT_DAYS_SUCCESS: gotDaysSuccess,
    GOT_ITEMS_ERROR: gotItemsError,
    GOT_PARTIAL_PAST_DAYS: gotPartialPastDays,
    GOT_PARTIAL_FUTURE_DAYS: gotPartialFutureDays,
    GOT_PARTIAL_WEEK_DAYS: gotPartialWeekDays,
    START_LOADING_OPPORTUNITIES: (state, _action) => {
      return {...state, loadingOpportunities: true}
    },
    START_LOADING_ALL_OPPORTUNITIES: (state, _action) => {
      return {...state, loadingOpportunities: true, allOpportunitiesLoaded: false}
    },
    START_LOADING_ITEMS: (state, _action) => {
      return loadingState(state, {isLoading: true})
    },
    GETTING_PAST_ITEMS: (state, action) => {
      return loadingState(state, {
        loadingError: state.loadingError, // don't reset error until we're successful
        loadingPast: true,
        seekingNewActivity: action.payload.seekingNewActivity,
      })
    },
    PEEKED_INTO_PAST: (state, action) => {
      return loadingState(state, {
        hasSomeItems: action.payload.hasSomeItems,
        allPastItemsLoaded: !action.payload.hasSomeItems,
        isLoading: state.isLoading,
      })
    },
    GETTING_FUTURE_ITEMS: (state, _action) => {
      return loadingState(state, {
        loadingError: state.loadingError, // don't reset error until we're successful
        loadingFuture: true,
      })
    },
    DELETED_PLANNER_ITEM: (state, _action) => {
      return loadingState(state, {hasSomeItems: false}) // because we can no longer be sure
    },
    SAVED_PLANNER_ITEM: (state, _action) => {
      return loadingState(state, {hasSomeItems: true}) // even if days[] is empty, we know we have an item
    },
    ALL_FUTURE_ITEMS_LOADED: (state, _action) => {
      return loadingState(state, {allFutureItemsLoaded: true})
    },
    ALL_WEEK_ITEMS_LOADED: (state, _action) => {
      return loadingState(state, {allWeekItemsLoaded: true})
    },
    ALL_OPPORTUNITIES_LOADED: (state, _action) => {
      return {...state, loadingOpportunities: false, allOpportunitiesLoaded: true}
    },
    ALL_PAST_ITEMS_LOADED: (state, _action) => {
      return loadingState(state, {allPastItemsLoaded: true})
    },
    ADD_OPPORTUNITIES: (state, _action) => {
      return {...state, loadingOpportunities: false}
    },
    START_LOADING_GRADES_SAGA: (state, _action) => ({
      ...state,
      loadingGrades: true,
      gradesLoadingError: null,
    }),
    GOT_GRADES_SUCCESS: (state, _action) => ({
      ...state,
      loadingGrades: false,
      gradesLoaded: true,
      gradesLoadingError: null,
    }),
    GOT_GRADES_ERROR: (state, action) => ({
      ...state,
      loadingGrades: false,
      gradesLoaded: false,
      gradesLoadingError: action.payload.message,
    }),
    GETTING_INIT_WEEK_ITEMS: (state, _action) => {
      return loadingState(state, {
        loadingError: state.loadingError, // don't reset error until we're successful
        isLoading: true,
        loadingWeek: true,
        allWeekItemsLoaded: false, // because it only refers to the week about to get loaded
      })
    },
    GETTING_WEEK_ITEMS: (state, _action) => {
      return loadingState(state, {
        loadingError: state.loadingError, // don't reset error until we're successful
        loadingWeek: true,
        allWeekItemsLoaded: false, // because it only refers to the week about to get loaded
      })
    },
    WEEK_LOADED: (state, _action) => {
      return loadingState(state, {
        loadingError: null,
        isLoading: false,
        hasSomeItems: true,
        loadingWeek: false,
      })
    },
    JUMP_TO_WEEK: (state, _action) => {
      return loadingState(state, {loadingWeek: false})
    },
    JUMP_TO_THIS_WEEK: (state, _action) => {
      return loadingState(state, {loadingWeek: false})
    },
    CLEAR_LOADING: (_state, _action) => INITIAL_STATE,
  },
  loadingState({}, INITIAL_STATE)
)

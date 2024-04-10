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

import {createActions, createAction} from 'redux-actions'
import axios from 'axios'
import {asAxios, getPrefetchedXHR} from '@canvas/util/xhr'
import {
  getContextCodesFromState,
  transformApiToInternalItem,
  observedUserId,
  observedUserContextCodes,
  buildURL,
} from '../utilities/apiUtils'
import {alert} from '../utilities/alertUtils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {itemsToDays} from '../utilities/daysUtils'

const I18n = useI18nScope('planner')

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
  gettingInitWeekItems,
  gettingWeekItems,
  startLoadingWeekSaga,
  weekLoaded,
  allWeekItemsLoaded,
  jumpToWeek,
  jumpToThisWeek,
  gotWayPastItemDate,
  gotWayFutureItemDate,
  gotCourseList,
  clearLoading,
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
  'GETTING_INIT_WEEK_ITEMS',
  'GETTING_WEEK_ITEMS',
  'START_LOADING_WEEK_SAGA',
  'WEEK_LOADED',
  'ALL_WEEK_ITEMS_LOADED',
  'JUMP_TO_WEEK',
  'JUMP_TO_THIS_WEEK',
  'GOT_WAY_FUTURE_ITEM_DATE',
  'GOT_WAY_PAST_ITEM_DATE',
  'GOT_COURSE_LIST',
  'CLEAR_LOADING'
)

export const gettingPastItems = createAction(
  'GETTING_PAST_ITEMS',
  (opts = {seekingNewActivity: false}) => {
    return opts
  }
)

export const gotDaysSuccess = createAction('GOT_DAYS_SUCCESS', (newDays, response) => {
  return {internalDays: newDays, response}
})

export function gotItemsSuccess(newItems, response) {
  return gotDaysSuccess(itemsToDays(newItems), response)
}

export const gotPartialFutureDays = createAction('GOT_PARTIAL_FUTURE_DAYS', (newDays, response) => {
  return {internalDays: newDays, response}
})

export const gotPartialPastDays = createAction('GOT_PARTIAL_PAST_DAYS', (newDays, response) => {
  return {internalDays: newDays, response}
})

export function getFirstNewActivityDate(fromMoment) {
  // We are requesting ascending order and only grabbing the first item,
  // specifically so we know what the very oldest new activity is
  return (dispatch, getState) => {
    fromMoment = fromMoment.clone().subtract(6, 'months')
    const observed_user_id = observedUserId(getState())
    const params = {}
    let include
    if (observed_user_id && !getState().singleCourse) {
      include = ['account_calendars', 'all_courses']
    } else if (getState().singleCourse) {
      params.context_codes = observedUserContextCodes(getState())
    }

    const url = buildURL('/api/v1/planner/items', {
      ...params,
      start_date: fromMoment.toISOString(),
      include,
      filter: 'new_activity',
      order: 'asc',
      observed_user_id,
    })

    const request = asAxios(getPrefetchedXHR(url)) || axios.get(url)

    return request
      .then(response => {
        if (response.data.length) {
          const first = transformApiToInternalItem(
            response.data[0],
            getState().courses,
            getState().groups,
            getState().timeZone
          )
          dispatch(foundFirstNewActivityDate(first.dateBucketMoment))
        }
      })
      .catch(_ex => alert(I18n.t('Failed to get new activity'), true))
  }
}

// this is the initial load
export function getPlannerItems(fromMoment) {
  return dispatch => {
    dispatch(startLoadingItems())
    return dispatch(getCourseList()) // classic planner never does singleCourse
      .then(res => {
        res.data.forEach(c => {
          c.color = ENV.PREFERENCES?.custom_colors[c.assetString] || '#666666'
        })
        dispatch(gotCourseList(res.data))
        dispatch(continueLoadingInitialItems()) // a start counts as a continue for the ContinueInitialLoad animation
        dispatch(getFirstNewActivityDate(fromMoment))
        dispatch(peekIntoPastSaga())
        dispatch(startLoadingFutureSaga())
      })
      .catch(_ex => {
        alert(I18n.t('Failed getting course list'))
      })
  }
}

export function getCourseList() {
  return (dispatch, getState) => {
    if (getState().singleCourse) {
      return Promise.resolve({data: getState().courses}) // set via INITIAL_OPTIONS
    }
    const observeeId = observedUserId(getState())
    const observeeParam = observeeId ? `?observed_user_id=${observeeId}` : ''
    const url = `/api/v1/dashboard/dashboard_cards${observeeParam}`
    const request = asAxios(getPrefetchedXHR(url)) || axios.get(url)
    return request
  }
}

export function loadFutureItems(opts = {loadMoreButtonClicked: false}) {
  return (dispatch, getState) => {
    if (getState().loading.allFutureItemsLoaded) return
    dispatch(gettingFutureItems(opts))
    dispatch(startLoadingFutureSaga())
  }
}

export const scrollIntoPastAction = createAction('SCROLL_INTO_PAST')

function loadPastItems(byScrolling) {
  return (dispatch, getState) => {
    if (getState().loading.allPastItemsLoaded) return
    if (byScrolling) dispatch(scrollIntoPastAction())
    dispatch(
      gettingPastItems({
        seekingNewActivity: false,
      })
    )
    dispatch(startLoadingPastSaga())
  }
}

export function scrollIntoPast() {
  return loadPastItems(true)
}

export function loadPastButtonClicked() {
  return loadPastItems(false)
}

export const loadPastUntilNewActivity = () => dispatch => {
  dispatch(
    gettingPastItems({
      seekingNewActivity: true,
    })
  )
  dispatch(startLoadingPastUntilNewActivitySaga())
  return 'loadPastUntilNewActivity' // for testing
}

export const loadPastUntilToday = () => dispatch => {
  dispatch(
    gettingPastItems({
      seekingNewActivity: false,
    })
  )
  dispatch(startLoadingPastUntilTodaySaga())
  return 'loadPastUntilToday' // for testing
}

// ----------- week at a time -------------------
// k5 week-at-a-time initial load
export function getWeeklyPlannerItems(fromMoment) {
  return (dispatch, getState) => {
    dispatch(startLoadingItems())
    const coursesPromise = getState().singleCourse
      ? Promise.resolve({data: getState().courses}) // set in INITIAL_OPTIONS for the singleCourse case
      : dispatch(getCourseList())
    return coursesPromise
      .then(res => {
        dispatch(gotCourseList(res.data))
        const weeklyState = getState().weeklyDashboard
        dispatch(gettingInitWeekItems(weeklyState))
        dispatch(getWayFutureItem(fromMoment))
        dispatch(getWayPastItem(fromMoment))
        loadWeekItems(dispatch, getState)
      })
      .catch(_ex => {
        alert(I18n.t('Failed getting course list'))
      })
  }
}

export function preloadSurroundingWeeks() {
  return (dispatch, getState) => {
    loadWeekItems(dispatch, getState, -7)
    loadWeekItems(dispatch, getState, 7)
  }
}

export const gotPartialWeekDays = createAction('GOT_PARTIAL_WEEK_DAYS', (newDays, response) => {
  return {internalDays: newDays, response}
})

export function loadPastWeekItems() {
  return (dispatch, getState) => {
    const weekly = getState().weeklyDashboard
    const weekStart = weekly.weekStart.clone().add(-7, 'days')
    const weekEnd = weekly.weekEnd.clone().add(-7, 'days')
    dispatch(gettingWeekItems({weekStart, weekEnd}))
    if (weekStart.format() in weekly.weeks) {
      dispatch(jumpToWeek({weekDays: weekly.weeks[weekStart.format()]}))
    } else {
      loadWeekItems(dispatch, getState)
    }
    // Pre-load the week before the previous week if it isn't loaded yet
    const nextWeekStart = weekly.weekStart.clone().add(-14, 'days')
    if (!(nextWeekStart.format() in weekly.weeks)) {
      loadWeekItems(dispatch, getState, -7)
    }
  }
}

export function loadNextWeekItems() {
  return (dispatch, getState) => {
    const weekly = getState().weeklyDashboard
    const weekStart = weekly.weekStart.clone().add(7, 'days')
    const weekEnd = weekly.weekEnd.clone().add(7, 'days')
    dispatch(gettingWeekItems({weekStart, weekEnd}))
    if (weekStart.format() in weekly.weeks) {
      dispatch(jumpToWeek({weekDays: weekly.weeks[weekStart.format()]}))
    } else {
      loadWeekItems(dispatch, getState)
    }
    // Pre-load the week after the next week if it isn't loaded yet
    const nextWeekStart = weekly.weekStart.clone().add(14, 'days')
    if (!(nextWeekStart.format() in weekly.weeks)) {
      loadWeekItems(dispatch, getState, 7)
    }
  }
}

export function loadThisWeekItems() {
  return (dispatch, getState) => {
    const weekly = getState().weeklyDashboard
    const weekStart = weekly.thisWeek.clone()
    const weekEnd = weekStart.clone().add(6, 'days').endOf('day')
    dispatch(gettingWeekItems({weekStart, weekEnd}))
    if (weekStart.format() in weekly.weeks) {
      dispatch(jumpToThisWeek({weekDays: weekly.weeks[weekStart.format()]}))
    } else {
      // should never get here since this week is loaded on load
      loadWeekItems(dispatch, getState)
    }
  }
}

function loadWeekItems(dispatch, getState, preloadDays = 0) {
  const weekly = getState().weeklyDashboard
  const weekStart = weekly.weekStart.clone().add(preloadDays, 'days')
  const weekEnd = weekly.weekEnd.clone().add(preloadDays, 'days')
  dispatch(startLoadingWeekSaga({weekStart, weekEnd, isPreload: !!preloadDays}))
}

function getWayFutureItem(fromMoment) {
  // We are requesting desc order and only grabbing the
  // first item so we know what the most distant item is
  return (dispatch, getState) => {
    const state = getState()
    const observed_user_id = observedUserId(state)
    let include
    const params = {}
    if (observed_user_id) {
      if (!state.singleCourse) {
        include = ['account_calendars', 'all_courses']
      } else {
        params.context_codes = getContextCodesFromState(state)
      }
    } else {
      params.context_codes = state.singleCourse ? getContextCodesFromState(state) : undefined
    }
    const futureMoment = fromMoment.clone().tz('UTC').startOf('day').add(1, 'year')
    const url = buildURL('/api/v1/planner/items', {
      ...params,
      observed_user_id,
      end_date: futureMoment.toISOString(),
      include,
      order: 'desc',
      per_page: 1,
    })
    const request = asAxios(getPrefetchedXHR(url)) || axios.get(url)

    return request
      .then(response => {
        if (response.data.length) {
          const wayFutureItemDate = response.data[0].plannable_date
          dispatch(gotWayFutureItemDate(wayFutureItemDate))
        }
      })
      .catch(_ex => alert(I18n.t('Failed peeking into your future'), true))
  }
}

function getWayPastItem(fromMoment) {
  return (dispatch, getState) => {
    const state = getState()
    const observed_user_id = observedUserId(state)
    let include
    const params = {}
    if (observed_user_id) {
      if (!getState().singleCourse) {
        include = ['account_calendars', 'all_courses']
      } else {
        params.context_codes = getContextCodesFromState(state)
      }
    } else {
      params.context_codes = state.singleCourse ? getContextCodesFromState(state) : undefined
    }
    const pastMoment = fromMoment.clone().tz('UTC').startOf('day').add(-1, 'year')

    const url = buildURL('/api/v1/planner/items', {
      ...params,
      observed_user_id,
      start_date: pastMoment.toISOString(),
      include,
      order: 'asc',
      per_page: 1,
    })
    const request = asAxios(getPrefetchedXHR(url)) || axios.get(url)

    return request
      .then(response => {
        if (response.data.length) {
          const wayPastItemDate = response.data[0].plannable_date
          dispatch(gotWayPastItemDate(wayPastItemDate))
        }
      })
      .catch(_ex => {
        alert(I18n.t('Failed peeking into your past'), true)
      })
  }
}

// --------------------------------------------
export function sendBasicFetchRequest(baseUrl, params = {}) {
  const url = buildURL(baseUrl, params)
  return asAxios(getPrefetchedXHR(url)) || axios.get(url)
}

export function sendFetchRequest(loadingOptions) {
  const [urlPrefix, {params}] = fetchParams(loadingOptions)
  const url = buildURL(urlPrefix, params)
  const request = asAxios(getPrefetchedXHR(url)) || axios.get(url)
  return request.then(response => handleFetchResponse(loadingOptions, response))
  // no .catch: it's up to the sagas to handle errors
}

function fetchParams(loadingOptions) {
  let timeParam = 'start_date'
  let linkField = 'futureNextUrl'
  if (loadingOptions.mode === 'past') {
    timeParam = 'end_date'
    linkField = 'pastNextUrl'
  } else if (loadingOptions.mode === 'week') {
    linkField = 'weekNextUrl'
  }
  const nextPageUrl = loadingOptions.getState().loading[linkField]
  if (nextPageUrl) {
    return [nextPageUrl, {}]
  } else {
    const params = {
      [timeParam]: loadingOptions.fromMoment.toISOString(),
    }
    if (loadingOptions.mode === 'past') {
      params.order = 'desc'
    }
    if (loadingOptions.perPage) {
      params.per_page = loadingOptions.perPage
    }
    if (loadingOptions.extraParams) {
      Object.assign(params, loadingOptions.extraParams)
    }
    const observeeId = observedUserId(loadingOptions.getState())
    if (observeeId) {
      if (!loadingOptions.getState().singleCourse) {
        params.include = ['account_calendars', 'all_courses']
      } else {
        params.context_codes = observedUserContextCodes(loadingOptions.getState())
      }
      params.observed_user_id = observeeId
    }

    return ['/api/v1/planner/items', {params}]
  }
}

function handleFetchResponse(loadingOptions, response) {
  const transformedItems = transformItems(loadingOptions, response.data)
  return {response, transformedItems}
}

function transformItems(loadingOptions, items) {
  return items.map(item =>
    transformApiToInternalItem(
      item,
      loadingOptions.getState().courses,
      loadingOptions.getState().groups,
      loadingOptions.getState().timeZone
    )
  )
}

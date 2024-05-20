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

import axios from 'axios'
import parseLinkHeader from '@canvas/parse-link-header'
import {put, select, call, all, takeEvery} from 'redux-saga/effects'
import {getFirstLoadedMoment, getLastLoadedMoment} from '../utilities/dateUtils'
import {
  getContextCodesFromState,
  transformApiToInternalGrade,
  observedUserId,
  getResponseHeader,
} from '../utilities/apiUtils'
import {alert} from '../utilities/alertUtils'
import {useScope as useI18nScope} from '@canvas/i18n'

import {
  gotItemsError,
  sendBasicFetchRequest,
  sendFetchRequest,
  gotGradesSuccess,
  gotGradesError,
} from './loading-actions'
import {addOpportunities, allOpportunitiesLoaded} from './index'

import {
  mergeFutureItems,
  mergePastItems,
  mergePastItemsForNewActivity,
  mergePastItemsForToday,
  mergeWeekItems,
  consumePeekIntoPast,
} from './saga-actions'

const I18n = useI18nScope('planner')

const MAX_PAGE_SIZE = 100

export default function* allSagas() {
  yield all([call(watchForSagas)])
}

function* watchForSagas() {
  yield takeEvery('START_LOADING_PAST_SAGA', loadPastSaga)
  yield takeEvery('START_LOADING_FUTURE_SAGA', loadFutureSaga)
  yield takeEvery('START_LOADING_PAST_UNTIL_NEW_ACTIVITY_SAGA', loadPastUntilNewActivitySaga)
  yield takeEvery('START_LOADING_GRADES_SAGA', loadGradesSaga)
  yield takeEvery('START_LOADING_PAST_UNTIL_TODAY_SAGA', loadPastUntilTodaySaga)
  yield takeEvery('PEEK_INTO_PAST_SAGA', peekIntoPastSaga)
  yield takeEvery('START_LOADING_WEEK_SAGA', loadWeekSaga)
  yield takeEvery('START_LOADING_ALL_OPPORTUNITIES', loadAllOpportunitiesSaga)
}

// fromMomentFunction: function
//   arg: currentState
//   returns: the fromMoment that should be passed to the fetch request
// actionCreator: function
//   arg: transformedItems - an array of new items to merge into the state
//   arg: response - the response of the fetch
//   returns: an action that returns a thunk.
//     The thunk should return:
//        true if the conditions were met and we can stop loading items
//        false if the new items did not meet the conditions and we should load more items
// opts: for sendFetchRequest
//   intoThePast
function* loadingLoop(fromMomentFunction, actionCreator, opts = {}) {
  try {
    let currentState = null
    const getState = () => currentState // don't want create a new function inside a loop
    let continueLoading = true
    while (continueLoading) {
      currentState = yield select()
      if (currentState.singleCourse) {
        const context_codes = getContextCodesFromState(currentState)
        if (context_codes) {
          opts.extraParams = {...(opts.extraParams || {}), context_codes}
        }
      }
      const fromMoment = fromMomentFunction(currentState)
      const loadingOptions = {fromMoment, getState, ...opts}
      const {transformedItems, response} = yield call(sendFetchRequest, loadingOptions)
      const thunk = yield call(actionCreator, transformedItems, response)
      const stopLoading = yield put(thunk)
      // the saga lib catches exceptions thrown by `put` and returns undefined in that case.
      // make sure we got a boolean like we expect.
      if (typeof stopLoading !== 'boolean') {
        throw new Error(
          `saga error invoking action ${actionCreator.name}. It returned a non-boolean: ${stopLoading}`
        )
      }
      continueLoading = !stopLoading
    }
  } catch (e) {
    yield put(gotItemsError(e))
  }
}

export function* loadPastSaga() {
  yield* loadingLoop(fromMomentPast, mergePastItems, {mode: 'past'})
}

export function* loadFutureSaga() {
  yield* loadingLoop(fromMomentFuture, mergeFutureItems, {mode: 'future'})
}

export function* loadPastUntilNewActivitySaga() {
  yield* loadingLoop(fromMomentPast, mergePastItemsForNewActivity, {mode: 'past'})
}

export function* peekIntoPastSaga() {
  yield* loadingLoop(fromMomentPast, consumePeekIntoPast, {mode: 'past', perPage: 1})
}

export function* loadGradesSaga(action) {
  const userid = action.payload
  const loadingOptions = {
    params: {
      include: ['total_scores', 'current_grading_period_scores', 'restrict_quantitative_data'],
      enrollment_type: 'student',
      enrollment_state: 'active',
    },
  }
  if (userid !== null) {
    loadingOptions.params.include.push('observed_users')
    loadingOptions.params.observed_user_id = userid
  }
  try {
    // exhaust pagination because we really do need all the grades.
    let loadingUrl = '/api/v1/users/self/courses'
    const gradesData = {}
    while (loadingUrl != null) {
      const response = yield call(axios.get, loadingUrl, loadingOptions)
      response.data.forEach(apiData => {
        const internalGrade = transformApiToInternalGrade(apiData)
        gradesData[internalGrade.courseId] = internalGrade
      })

      const links = parseLinkHeader(getResponseHeader(response, 'link'))
      loadingUrl = links && links.next ? links.next.url : null
    }
    yield put(gotGradesSuccess(gradesData))
  } catch (loadingError) {
    yield put(gotGradesError(loadingError))
    throw loadingError
  }
}

export function* loadAllOpportunitiesSaga() {
  try {
    let loadingUrl = '/api/v1/users/self/missing_submissions'
    const items = []
    const {courses, singleCourse, selectedObservee, currentUser, weeklyDashboard} = yield select()
    const observed_user_id = observedUserId({selectedObservee, currentUser})
    let course_ids
    if (observed_user_id) {
      course_ids = courses.map(c => c.id)
    } else {
      course_ids = singleCourse ? courses.map(c => c.id) : undefined
    }
    while (loadingUrl != null) {
      const filter = ['submittable']
      if (weeklyDashboard) {
        filter.push('current_grading_period')
      }
      const response = yield call(sendBasicFetchRequest, loadingUrl, {
        observed_user_id,
        course_ids,
        include: ['planner_overrides'],
        filter,
        per_page: MAX_PAGE_SIZE,
      })
      items.push(...response.data)

      const links = parseLinkHeader(getResponseHeader(response, 'link'))
      loadingUrl = links?.next ? links.next.url : null
    }
    yield put(addOpportunities({items, nextUrl: null}))
    yield put(allOpportunitiesLoaded())
  } catch (err) {
    alert(I18n.t('Failed to load opportunities'), true)
  }
}

export function* loadPastUntilTodaySaga() {
  yield* loadingLoop(fromMomentPast, mergePastItemsForToday, {mode: 'past'})
}

export function* loadWeekSaga({payload: {weekStart, weekEnd, isPreload}}) {
  yield* loadingLoop(() => weekStart, mergeWeekItems(weekStart, isPreload), {
    mode: 'week',
    extraParams: {
      end_date: weekEnd.toISOString(),
      per_page: MAX_PAGE_SIZE,
    },
  })
}

function fromMomentPast(state) {
  return getFirstLoadedMoment(state.days, state.timeZone)
}

function fromMomentFuture(state) {
  const lastMoment = getLastLoadedMoment(state.days, state.timeZone)
  if (state.days.length) lastMoment.add(1, 'days')
  return lastMoment
}

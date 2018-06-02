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

import axios from 'axios';
import parseLinkHeader from 'parse-link-header';
import { put, select, call, all, takeEvery } from 'redux-saga/effects';
import { getFirstLoadedMoment, getLastLoadedMoment } from '../utilities/dateUtils';
import { transformApiToInternalGrade } from '../utilities/apiUtils';

import {
  gotItemsError, sendFetchRequest, gotGradesSuccess, gotGradesError,
} from './loading-actions';

import {
  mergeFutureItems, mergePastItems, mergePastItemsForNewActivity, mergePastItemsForToday
} from './saga-actions';


export default function* allSagas () {
  yield all([
    call(watchForSagas),
  ]);
}

function* watchForSagas () {
  yield takeEvery('START_LOADING_PAST_SAGA', loadPastSaga);
  yield takeEvery('START_LOADING_FUTURE_SAGA', loadFutureSaga);
  yield takeEvery('START_LOADING_PAST_UNTIL_NEW_ACTIVITY_SAGA', loadPastUntilNewActivitySaga);
  yield takeEvery('START_LOADING_GRADES_SAGA', loadGradesSaga);
  yield takeEvery('START_LOADING_PAST_UNTIL_TODAY_SAGA', loadPastUntilTodaySaga);
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
function* loadingLoop (fromMomentFunction, actionCreator, opts) {
  try {
    let currentState = null;
    const getState = () => currentState; // don't want create a new function inside a loop
    let continueLoading = true;
    while (continueLoading) {
      currentState = yield select();
      const fromMoment = fromMomentFunction(currentState);
      const loadingOptions = {fromMoment, getState, ...opts};
      const {transformedItems, response} = yield call(sendFetchRequest, loadingOptions);
      const thunk = yield call(actionCreator, transformedItems, response);
      continueLoading = !(yield put(thunk));
    }
  } catch (e) {
    yield put(gotItemsError(e));
    throw e;
  }
}

export function* loadPastSaga () {
  yield* loadingLoop(fromMomentPast, mergePastItems, {intoThePast: true});
}

export function* loadFutureSaga () {
  yield* loadingLoop(fromMomentFuture, mergeFutureItems, {intoThePast: false});
}

export function* loadPastUntilNewActivitySaga () {
  yield* loadingLoop(fromMomentPast, mergePastItemsForNewActivity, {intoThePast: true});
}

export function* loadGradesSaga () {
  const loadingOptions = {
    params: {
      include: ['total_scores', 'current_grading_period_scores'],
      enrollment_type: 'student',
      enrollment_state: 'active',
    },
  };
  try {
    // exhaust pagination because we really do need all the grades.
    let loadingUrl = '/api/v1/users/self/courses';
    let gradesData = {};
    while (loadingUrl != null) {
      const response = yield call(axios.get, loadingUrl, loadingOptions);
      response.data.forEach(apiData => {
        const internalGrade = transformApiToInternalGrade(apiData);
        gradesData[internalGrade.courseId] = internalGrade;
      });

      const links = parseLinkHeader(response.headers.link);
      loadingUrl = links && links.next ? links.next.url : null;
    }
    yield put(gotGradesSuccess(gradesData));
  } catch (loadingError) {
    yield put(gotGradesError(loadingError));
    throw loadingError;
  }
}

export function* loadPastUntilTodaySaga () {
  yield* loadingLoop(fromMomentPast, mergePastItemsForToday, {intoThePast: true});
}

function fromMomentPast (state) {
  return getFirstLoadedMoment(state.days, state.timeZone);
}

function fromMomentFuture (state) {
  const lastMoment = getLastLoadedMoment(state.days, state.timeZone);
  if (state.days.length) lastMoment.add(1, 'days');
  return lastMoment;
}

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
import moment from 'moment-timezone'
import {select, call, put} from 'redux-saga/effects'
import {
  gotItemsError,
  sendBasicFetchRequest,
  sendFetchRequest,
  gotGradesSuccess,
  gotGradesError,
} from '../loading-actions'
import {addOpportunities, allOpportunitiesLoaded} from '..'
import {
  loadAllOpportunitiesSaga,
  loadPastUntilNewActivitySaga,
  loadPastSaga,
  loadFutureSaga,
  loadGradesSaga,
  peekIntoPastSaga,
  loadWeekSaga,
} from '../sagas'
import {
  mergeFutureItems,
  mergePastItems,
  mergePastItemsForNewActivity,
  consumePeekIntoPast,
  mergeWeekItems,
} from '../saga-actions'
import {initialize} from '../../utilities/alertUtils'
import {transformApiToInternalGrade} from '../../utilities/apiUtils'

const TZ = 'Asia/Tokyo'

function initialState(overrides = {}) {
  const thisWeekStart = moment.tz(TZ).startOf('week')
  return {
    loading: {seekingNewActivity: true},
    courses: [],
    days: [],
    opportunities: [],
    timeZone: TZ,
    weeklyDashboard: {
      weekStart: thisWeekStart,
      weekEnd: moment.tz(TZ).endOf('week'),
      thisWeek: thisWeekStart,
      weeks: {},
    },
    ...overrides,
  }
}

function setupLoadingPastUntilNewActivitySaga() {
  const generator = loadPastUntilNewActivitySaga()
  generator.next()
  generator.next(initialState())
  return generator
}

describe('loadPastUntilNewActivitySaga', () => {
  it('sends a fetch request for past items', () => {
    const generator = loadPastUntilNewActivitySaga()
    expect(generator.next().value).toEqual(select())
    const currentState = initialState()
    const startOfDay = moment.tz(currentState.timeZone).startOf('day')
    expect(generator.next(currentState).value).toEqual(
      call(sendFetchRequest, {
        getState: expect.any(Function),
        fromMoment: startOfDay,
        mode: 'past',
      })
    )
  })

  it('an iteration calls sendFetchRequest, calls the action creator, puts the thunk, and quits', () => {
    const generator = setupLoadingPastUntilNewActivitySaga()
    expect(
      generator.next({transformedItems: 'some items', response: 'some response'}).value
    ).toEqual(call(mergePastItemsForNewActivity, 'some items', 'some response'))
    expect(generator.next('a thunk').value).toEqual(put('a thunk'))
    expect(generator.next(true).done).toBeTruthy()
  })

  it('loops when the thunk returns false', () => {
    const generator = setupLoadingPastUntilNewActivitySaga()
    generator.next('fetch result')
    generator.next('a thunk')
    const nextIteration = generator.next(false)
    expect(nextIteration.done).toBeFalsy()
    expect(nextIteration.value).toEqual(select())
    expect(generator.next(initialState()).value).toEqual(call(sendFetchRequest, expect.anything()))
  })

  it('aborts and reports if the fetch fails', () => {
    const generator = setupLoadingPastUntilNewActivitySaga()
    const expectedError = new Error('some error')
    expect(generator.throw(expectedError).value).toEqual(put(gotItemsError(expectedError)))
  })

  it('aborts if the reducers throw on a put effect', () => {
    const generator = setupLoadingPastUntilNewActivitySaga()
    generator.next('fetch result')
    generator.next('a thunk')
    generator.next(undefined) // simulate what happens when reducers throw
    expect(generator.next().done).toBe(true)
  })
})

describe('loadPastSaga', () => {
  it('uses the past methods', () => {
    const generator = loadPastSaga()
    generator.next()
    expect(generator.next(initialState()).value).toEqual(
      call(sendFetchRequest, {
        getState: expect.any(Function),
        fromMoment: moment.tz(TZ).startOf('day'),
        mode: 'past',
      })
    )
    expect(generator.next({transformedItems: 'some items', response: 'response'}).value).toEqual(
      call(mergePastItems, 'some items', 'response')
    )
  })

  // not doing a full sequence of tests because the code is shared with the above saga
})

describe('peekIntoPastSaga', () => {
  it('peeks into past', () => {
    const generator = peekIntoPastSaga()
    generator.next()
    expect(generator.next(initialState()).value).toEqual(
      call(sendFetchRequest, {
        getState: expect.any(Function),
        fromMoment: moment.tz(TZ).startOf('day'),
        mode: 'past',
        perPage: 1,
      })
    )
    expect(generator.next({transformedItems: ['some items'], response: 'response'}).value).toEqual(
      call(consumePeekIntoPast, ['some items'], 'response')
    )
  })
})

describe('loadFutureSaga', () => {
  it('uses the future methods', () => {
    const generator = loadFutureSaga()
    generator.next()
    expect(generator.next(initialState()).value).toEqual(
      call(sendFetchRequest, {
        getState: expect.any(Function),
        fromMoment: moment.tz(TZ).startOf('day'),
        mode: 'future',
      })
    )
    expect(generator.next({transformedItems: 'some items', response: 'response'}).value).toEqual(
      call(mergeFutureItems, 'some items', 'response')
    )
  })

  // not doing a full sequence of tests because the code is shared with the above saga
})

function mockCourse(opts = {grade: '42.34'}) {
  return {
    id: '1',
    has_grading_periods: true,
    enrollments: [{current_period_computed_current_grade: opts.grade}],
    ...opts,
  }
}

describe('loadGradesSaga', () => {
  it('passes correct parameters to the api', () => {
    const generator = loadGradesSaga({payload: null})
    expect(generator.next().value).toEqual(
      call(axios.get, '/api/v1/users/self/courses', {
        params: {
          include: ['total_scores', 'current_grading_period_scores', 'restrict_quantitative_data'],
          enrollment_type: 'student',
          enrollment_state: 'active',
        },
      })
    )
  })
  it('passes correct observee parameters to the api', () => {
    const generator = loadGradesSaga({payload: '17'})
    expect(generator.next().value).toEqual(
      call(axios.get, '/api/v1/users/self/courses', {
        params: {
          include: [
            'total_scores',
            'current_grading_period_scores',
            'restrict_quantitative_data',
            'observed_users',
          ],
          enrollment_type: 'student',
          enrollment_state: 'active',
          observed_user_id: '17',
        },
      })
    )
  })

  it('exhausts pagination', () => {
    const generator = loadGradesSaga({payload: 'self'})
    generator.next()
    expect(
      generator.next({
        headers: {link: '<some-url>; rel="next"'},
        data: [],
      }).value
    ).toEqual(call(axios.get, expect.anything(), expect.anything()))
    generator.next({headers: {}, data: []}) // put
    expect(generator.next().done).toBe(true)
  })

  it('puts gotGradesSuccess when all data is loaded', () => {
    const generator = loadGradesSaga({payload: 'self'})
    const mockCourses = [mockCourse({id: '1', grade: '42.3'}), mockCourse({id: '2', grade: '34.4'})]
    generator.next()
    const putResult = generator.next({
      headers: {},
      data: mockCourses,
    })
    expect(putResult.value).toEqual(
      put(
        gotGradesSuccess({
          1: transformApiToInternalGrade(mockCourses[0]),
          2: transformApiToInternalGrade(mockCourses[1]),
        })
      )
    )
    expect(generator.next().done).toBe(true)
  })

  it('puts gotGradesError if there is a loading error', () => {
    const generator = loadGradesSaga({payload: 'self'})
    generator.next()
    expect(generator.throw('some-error').value).toEqual(put(gotGradesError('some-error')))
    expect(() => generator.next()).toThrow()
  })
})

describe('loadWeekSaga', () => {
  it('uses the weekly methods', () => {
    const state = initialState()
    const generator = loadWeekSaga({
      payload: {
        weekStart: state.weeklyDashboard.weekStart,
        weekEnd: state.weeklyDashboard.weekEnd,
      },
    })
    generator.next()
    expect(generator.next(state).value).toEqual(
      call(sendFetchRequest, {
        getState: expect.any(Function),
        fromMoment: state.weeklyDashboard.weekStart,
        mode: 'week',
        extraParams: {
          end_date: state.weeklyDashboard.weekEnd.toISOString(),
          per_page: 100,
        },
      })
    )
    expect(
      JSON.stringify(generator.next({transformedItems: 'some items', response: 'response'}).value)
    ).toEqual(JSON.stringify(call(mergeWeekItems(), 'some items', 'response')))
  })
  // We're not testing all the scenarios, like multiple pages of items in a week
})

describe('loadAllOpportunitiesSaga', () => {
  it('passes page size param to API call', () => {
    const generator = loadAllOpportunitiesSaga()
    generator.next() // select state
    expect(generator.next(initialState()).value).toEqual(
      call(sendBasicFetchRequest, '/api/v1/users/self/missing_submissions', {
        course_ids: undefined,
        include: ['planner_overrides'],
        filter: ['submittable', 'current_grading_period'],
        per_page: 100,
        observed_user_id: null,
      })
    )
  })

  it('exhausts pagination', () => {
    const generator = loadAllOpportunitiesSaga()
    generator.next() // start saga
    generator.next(initialState()) // select state
    // fetch opportunities
    expect(
      generator.next({
        headers: {link: '<some-url>; rel="next"'},
        data: [],
      }).value
    ).toEqual(call(sendBasicFetchRequest, expect.anything(), expect.anything()))
    generator.next({headers: {}, data: []}) // add opportunities
    generator.next() // mark all opportunities as loaded
    expect(generator.next().done).toBe(true)
  })

  it('puts addOpportunities and allOpportunitiesLoaded when all data is loaded', () => {
    const mockOpps = [
      {id: '2', name: 'Assignment 1'},
      {id: '5', name: 'Assignment 2'},
    ]
    const generator = loadAllOpportunitiesSaga()
    generator.next() // start saga
    generator.next(initialState()) // select state
    // fetch opportunities
    const putResult = generator.next({
      data: mockOpps,
      headers: {},
    })
    // add opportunities
    expect(putResult.value).toEqual(put(addOpportunities({items: mockOpps, nextUrl: null})))
    // mark all opportunities as loaded
    expect(generator.next().value).toEqual(put(allOpportunitiesLoaded()))
    expect(generator.next().done).toBeTruthy()
  })

  it('filters the requests to specific contexts if in singleCourse mode', () => {
    const overrides = {courses: [{id: '3'}], singleCourse: true}
    const generator = loadAllOpportunitiesSaga()
    generator.next() // start saga
    const callResult = generator.next(initialState(overrides)) // select state
    expect(callResult.value.CALL.args[1]).toMatchObject({
      course_ids: ['3'],
    })
  })

  it('alerts if there is a loading error', () => {
    const alertSpy = jest.fn()
    initialize({visualErrorCallback: alertSpy})
    const generator = loadAllOpportunitiesSaga()
    generator.next() // start saga
    generator.next(initialState()) // select state
    generator.throw('some-error')
    expect(alertSpy).toHaveBeenCalled()
  })

  it('passes observed_user_id and course_ids to API call if observing', () => {
    const overrides = {
      courses: [
        {id: '1', assetString: 'course_1'},
        {id: '569', assetString: 'course_569'},
      ],
      currentUser: {
        id: '3',
      },
      selectedObservee: '12',
    }
    const generator = loadAllOpportunitiesSaga()
    generator.next() // select state
    expect(generator.next(initialState(overrides)).value).toEqual(
      call(sendBasicFetchRequest, '/api/v1/users/self/missing_submissions', {
        observed_user_id: '12',
        course_ids: ['1', '569'],
        include: ['planner_overrides'],
        filter: ['submittable', 'current_grading_period'],
        per_page: 100,
      })
    )
  })
})

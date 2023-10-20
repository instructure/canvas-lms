/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import moment from 'moment-timezone'
import weeklyReducer from '../weekly-reducer'
import * as Actions from '../../actions/loading-actions'

const TZ = 'Asia/Tokyo'

function initialState(opts = {}) {
  return {
    ...weeklyReducer(undefined, {
      type: 'INITIAL_OPTIONS',
      payload: {
        env: {
          TIMEZONE: TZ,
          K5_USER: true,
          K5_SUBJECT_COURSE: true,
          FEATURES: {},
        },
      },
    }),
    ...opts,
  }
}

it('sets weekStart/End to this week on initialization', () => {
  const initState = initialState()
  const thisWeekStart = moment.tz(TZ).startOf('week')
  const thisWeekEnd = moment.tz(TZ).endOf('week')
  expect(initState.weekStart.format()).toEqual(thisWeekStart.format())
  expect(initState.weekEnd.format()).toEqual(thisWeekEnd.format())
  expect(initState.thisWeek.format()).toEqual(thisWeekStart.format())
})

it('sets loading to true on START_LOADING_ITEMS', () => {
  const initState = initialState()
  const nextWeek = {
    weekStart: initState.weekStart.clone().add(7, 'days'),
    weekEnd: initState.weekEnd.clone().add(7, 'days'),
  }
  const newState = weeklyReducer(initState, Actions.gettingWeekItems(nextWeek))
  expect(newState).toMatchObject(nextWeek)
})

it('adds new week data to state', () => {
  const thisWeekStart = moment.tz(TZ).startOf('week')
  // start with this week's data
  const initState = initialState({
    weeks: {
      [thisWeekStart.format()]: ['first week data'],
    },
    weekStart: thisWeekStart,
  })
  // start loading next week
  const nextWeek = {
    weekStart: initState.weekStart.clone().add(7, 'days'),
    weekEnd: initState.weekEnd.clone().add(7, 'days'),
  }
  const newState = weeklyReducer(initState, Actions.gettingWeekItems(nextWeek))

  // next week is loaded
  const newerState = weeklyReducer(
    newState,
    Actions.weekLoaded({
      weekDays: ['next week data'],
      weekStart: initState.weekStart.clone().add(7, 'days'),
    })
  )

  expect(newerState.weeks).toMatchObject({
    ...initState.weeks,
    [newState.weekStart.format()]: ['next week data'],
  })
})

it('sets way past date', () => {
  const initState = initialState()
  const newState = weeklyReducer(initState, Actions.gotWayPastItemDate('2000-01-01'))
  expect(newState.wayPastItemDate).toEqual('2000-01-01')
})

it('sets way future date', () => {
  const initState = initialState()
  const newState = weeklyReducer(initState, Actions.gotWayPastItemDate('3000-01-01'))
  expect(newState.wayPastItemDate).toEqual('3000-01-01')
})

it('clears week data', () => {
  const thisWeekStart = moment.tz(TZ).startOf('week')
  const initState = initialState({
    weeks: {
      [thisWeekStart.format()]: ['first week data'],
    },
  })
  const newState = weeklyReducer(initState, {type: 'CLEAR_WEEKLY_ITEMS'})
  expect(newState.weeks).toEqual({})
})

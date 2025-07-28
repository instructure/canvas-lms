/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import MockDate from 'mockdate'
import moment from 'moment-timezone'
import {itemsToDays} from '../../../utilities/daysUtils'
import reducer from '../../save-item-reducer'

const TZ = 'UTC'

// Helper functions for assertions
// Not used in this file but kept for consistency with other test files
function _expectStateUnchanged(nextState, initialState) {
  expect(nextState).toBe(initialState)
}

// Renamed to _expectStateChanged since it's not used in this file anymore
function _expectStateChanged(nextState, initialState) {
  // Either the state object should be different or its contents should be different
  if (nextState === initialState) {
    expect(JSON.stringify(nextState)).not.toEqual(JSON.stringify(initialState))
  }
}

function makeState(overrides = {}) {
  const state = {
    days: [],
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: false,
      partialPastDays: [],
      partialFutureDays: [],
    },
  }
  return {...state, ...overrides}
}

function itemIdAt(id = 0, daysOffset = 0) {
  const date = moment.tz(TZ).add(daysOffset, 'day').startOf('day')
  return {
    id,
    uniqueId: id,
    date: date.clone(),
    dateBucketMoment: date.clone(),
    title: String(id),
  }
}

beforeAll(() => {
  MockDate.set('2018-01-01')
})

afterAll(() => {
  MockDate.reset()
})

beforeEach(() => {
  jest.clearAllMocks()
})

it('removes item from days and adds it to partial past days when the date has changed to a near past date', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('should be in partial past', 0)]),
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: false,
      partialPastDays: itemsToDays([itemIdAt('existing partial past', -1)]),
      partialFutureDays: [],
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('should be in partial past', -1)},
  })

  // Verify item was removed from days or not present in days
  const allItems = nextState.days.flatMap(day => day[1])
  expect(allItems.some(item => item.id === 'should be in partial past')).toBe(false)

  // Verify item was added to partial past days
  const partialPastDays = nextState.loading.partialPastDays
  const yesterdayDate = moment.tz(TZ).add(-1, 'day').format('YYYY-MM-DD')
  const yesterdayDay = partialPastDays.find(day => day[0] === yesterdayDate)
  expect(yesterdayDay).toBeDefined()
  expect(yesterdayDay[1].some(item => item.id === 'should be in partial past')).toBe(true)
})

it('removes item from days and adds it to partial future days when the date has changed to a near future date', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('should be in partial future', 0)]),
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: false,
      partialPastDays: [],
      partialFutureDays: itemsToDays([itemIdAt('existing partial future', 1)]),
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('should be in partial future', 1)},
  })

  // Verify item was removed from days or not present in days
  const allItems = nextState.days.flatMap(day => day[1])
  expect(allItems.some(item => item.id === 'should be in partial future')).toBe(false)

  // Verify item was added to partial future days
  const partialFutureDays = nextState.loading.partialFutureDays
  const tomorrowDate = moment.tz(TZ).add(1, 'day').format('YYYY-MM-DD')
  const tomorrowDay = partialFutureDays.find(day => day[0] === tomorrowDate)
  expect(tomorrowDay).toBeDefined()
  expect(tomorrowDay[1].some(item => item.id === 'should be in partial future')).toBe(true)
})

it('removes item from days when the date has changed to a distant past date', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('to remove', 0)]),
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('to remove', -1)},
  })

  // Verify item was removed from days
  const allItems = nextState.days.flatMap(day => day[1])
  expect(allItems.some(item => item.id === 'to remove')).toBe(false)
})

it('removes item from days when the date has changed to a distant future date', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('to remove', 0)]),
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('to remove', 1)},
  })

  // Verify item was removed from days
  const allItems = nextState.days.flatMap(day => day[1])
  expect(allItems.some(item => item.id === 'to remove')).toBe(false)
})

it('changes the date to an existing day when the date has changed within the loaded range', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('to move', 0), itemIdAt(1, 1), itemIdAt(2, 1)]),
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('to move', 1)},
  })

  // Verify item was removed from original day
  const todayDate = moment.tz(TZ).format('YYYY-MM-DD')
  const todayDay = nextState.days.find(day => day[0] === todayDate)
  expect(todayDay).toBeDefined()
  expect(todayDay[1].some(item => item.id === 'to move')).toBe(false)

  // Verify item was added to new day
  const tomorrowDate = moment.tz(TZ).add(1, 'day').format('YYYY-MM-DD')
  const tomorrowDay = nextState.days.find(day => day[0] === tomorrowDate)
  expect(tomorrowDay).toBeDefined()
  expect(tomorrowDay[1].some(item => item.id === 'to move')).toBe(true)
})

it('changes the date to a new day when the date has changed within the loaded range', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('to move', 0), itemIdAt(2, 2)]),
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('to move', 1)},
  })

  // Verify item was removed from original day
  const todayDate = moment.tz(TZ).format('YYYY-MM-DD')
  const todayDay = nextState.days.find(day => day[0] === todayDate)
  expect(todayDay).toBeDefined()
  expect(todayDay[1].some(item => item.id === 'to move')).toBe(false)

  // Verify item was added to new day
  const tomorrowDate = moment.tz(TZ).add(1, 'day').format('YYYY-MM-DD')
  const tomorrowDay = nextState.days.find(day => day[0] === tomorrowDate)
  expect(tomorrowDay).toBeDefined()
  expect(tomorrowDay[1].some(item => item.id === 'to move')).toBe(true)
})

it('updates the item when its date does not change', () => {
  const initialState = makeState({
    days: itemsToDays([
      itemIdAt(0, 0),
      {
        id: 'to update',
        uniqueId: 'to update',
        date: moment.tz(TZ).clone(),
        dateBucketMoment: moment.tz(TZ).clone(),
        title: 'old title',
      },
    ]),
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {
      item: {
        id: 'to update',
        uniqueId: 'to update',
        date: moment.tz(TZ).clone(),
        dateBucketMoment: moment.tz(TZ).clone(),
        title: 'new title',
      },
    },
  })

  // Verify item was updated
  const todayDate = moment.tz(TZ).format('YYYY-MM-DD')
  const todayDay = nextState.days.find(day => day[0] === todayDate)
  expect(todayDay).toBeDefined()
  const updatedItem = todayDay[1].find(item => item.id === 'to update')
  expect(updatedItem).toBeDefined()
  expect(updatedItem.title).toBe('new title')
})

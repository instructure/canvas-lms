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
import {savedPlannerItem} from '../../../actions'
import reducer from '../../save-item-reducer'

const TZ = 'UTC'

// Helper functions for assertions
function expectStateUnchanged(nextState, initialState) {
  expect(nextState).toBe(initialState)
}

function expectStateChanged(nextState, initialState) {
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

it('adds a new item to a new day when the new date is within the loaded range', () => {
  const initialState = makeState({days: itemsToDays([itemIdAt(0, 0), itemIdAt(2, 2)])})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new', 1)}))
  expectStateChanged(nextState, initialState)

  // Verify a new day was added with the item
  expect(nextState.days.length).toBeGreaterThan(initialState.days.length)
  const tomorrowDate = moment.tz(TZ).add(1, 'day').format('YYYY-MM-DD')
  const tomorrowDay = nextState.days.find(day => day[0] === tomorrowDate)
  expect(tomorrowDay).toBeDefined()
  expect(tomorrowDay[1].some(item => item.id === 'new')).toBe(true)
})

it('adds a new item to an existing day when the new date is within the loaded range', () => {
  const initialState = makeState({days: itemsToDays([itemIdAt(0, 0), itemIdAt(1, 1)])})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new', 1)}))
  expectStateChanged(nextState, initialState)

  // Verify item was added to the existing day
  const tomorrowDate = moment.tz(TZ).add(1, 'day').format('YYYY-MM-DD')
  const tomorrowDay = nextState.days.find(day => day[0] === tomorrowDate)
  expect(tomorrowDay).toBeDefined()
  expect(tomorrowDay[1].some(item => item.id === 'new')).toBe(true)
})

it('adds an item to today even when the only loaded items are in the future', () => {
  const initialState = makeState({days: itemsToDays([itemIdAt(1, 1)])})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new today', 0)}))
  expectStateChanged(nextState, initialState)

  // Verify item was added to today
  const todayDate = moment.tz(TZ).format('YYYY-MM-DD')
  const todayDay = nextState.days.find(day => day[0] === todayDate)
  expect(todayDay).toBeDefined()
  expect(todayDay[1].some(item => item.id === 'new today')).toBe(true)
})

it('adds a new item to a new day when the loaded range is open ended in the past', () => {
  const initialState = makeState({
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: true,
      allFutureItemsLoaded: false,
      partialPastDays: [],
      partialFutureDays: [],
    },
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new past', -1)}))
  expectStateChanged(nextState, initialState)

  // Verify a new day was added with the item
  expect(nextState.days.length).toBeGreaterThan(0)
  const yesterdayDate = moment.tz(TZ).add(-1, 'day').format('YYYY-MM-DD')
  const yesterdayDay = nextState.days.find(day => day[0] === yesterdayDate)
  expect(yesterdayDay).toBeDefined()
  expect(yesterdayDay[1].some(item => item.id === 'new past')).toBe(true)
})

it('adds a new item to a new day when the loaded range is open ended in the future', () => {
  const initialState = makeState({
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: true,
      partialPastDays: [],
      partialFutureDays: [],
    },
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new future', 1)}))
  expectStateChanged(nextState, initialState)

  // Verify a new day was added with the item
  expect(nextState.days.length).toBeGreaterThan(0)
  const tomorrowDate = moment.tz(TZ).add(1, 'day').format('YYYY-MM-DD')
  const tomorrowDay = nextState.days.find(day => day[0] === tomorrowDate)
  expect(tomorrowDay).toBeDefined()
  expect(tomorrowDay[1].some(item => item.id === 'new future')).toBe(true)
})

it('inserts a today item into days if the state is empty', () => {
  const initialState = makeState()
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('today item', 0)}))
  expectStateChanged(nextState, initialState)

  // Verify today was added with the item
  expect(nextState.days).toHaveLength(1)
  const todayDate = moment.tz(TZ).format('YYYY-MM-DD')
  expect(nextState.days[0][0]).toBe(todayDate)
  expect(nextState.days[0][1].some(item => item.id === 'today item')).toBe(true)
})

it('inserts a past item into days if state is empty and allPastItemsLoaded', () => {
  const initialState = makeState({
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: true,
      allFutureItemsLoaded: false,
      partialPastDays: [],
      partialFutureDays: [],
    },
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('past item', -1)}))
  expectStateChanged(nextState, initialState)

  // Verify past day was added with the item
  expect(nextState.days).toHaveLength(1)
  const yesterdayDate = moment.tz(TZ).add(-1, 'day').format('YYYY-MM-DD')
  expect(nextState.days[0][0]).toBe(yesterdayDate)
  expect(nextState.days[0][1].some(item => item.id === 'past item')).toBe(true)
})

it('inserts a future item into days if the state is empty and allFutureItemsLoaded', () => {
  const initialState = makeState({
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: true,
      partialPastDays: [],
      partialFutureDays: [],
    },
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('future item', 1)}))
  expectStateChanged(nextState, initialState)

  // Verify future day was added with the item
  expect(nextState.days).toHaveLength(1)
  const tomorrowDate = moment.tz(TZ).add(1, 'day').format('YYYY-MM-DD')
  expect(nextState.days[0][0]).toBe(tomorrowDate)
  expect(nextState.days[0][1].some(item => item.id === 'future item')).toBe(true)
})

it('does not insert a past item into days if the state is empty and past is not loaded', () => {
  const initialState = makeState()
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('past item', -1)}))
  expectStateUnchanged(nextState, initialState)
})

it('inserts an item into last loaded day even when it is after startOf("day")', () => {
  const initialState = makeState({days: itemsToDays([itemIdAt(0, 0), itemIdAt(1, 1)])})
  const item = itemIdAt('new', 1)
  item.date = moment.tz(TZ).add(1, 'day').add(1, 'hour')
  const nextState = reducer(initialState, savedPlannerItem({item}))
  expectStateChanged(nextState, initialState)

  // Verify item was added to the existing day
  const tomorrowDate = moment.tz(TZ).add(1, 'day').format('YYYY-MM-DD')
  const tomorrowDay = nextState.days.find(day => day[0] === tomorrowDate)
  expect(tomorrowDay).toBeDefined()
  expect(tomorrowDay[1].some(item => item.id === 'new')).toBe(true)
})

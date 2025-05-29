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
function expectStateUnchanged(nextState, initialState) {
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

it('adds a new item to partial past days when the new date is after the near past boundary but outside loaded range', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0)]),
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: false,
      partialPastDays: itemsToDays([itemIdAt('existing past partial -3', -3)]),
      partialFutureDays: [],
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('new past partial', -2)},
  })

  // Verify item was added to partial past days
  const partialPastDays = nextState.loading.partialPastDays
  const twoDaysAgoDate = moment.tz(TZ).add(-2, 'day').format('YYYY-MM-DD')
  const twoDaysAgoDay = partialPastDays.find(day => day[0] === twoDaysAgoDate)
  expect(twoDaysAgoDay).toBeDefined()
  expect(twoDaysAgoDay[1].some(item => item.id === 'new past partial')).toBe(true)
})

it('adds a new item to partial past days when the new date is within the partial past date range', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0)]),
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: false,
      partialPastDays: itemsToDays([
        itemIdAt('existing past partial -3', -3),
        itemIdAt('existing past partial -1', -1),
      ]),
      partialFutureDays: [],
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('new past partial', -2)},
  })

  // Verify item was added to partial past days
  const partialPastDays = nextState.loading.partialPastDays
  const twoDaysAgoDate = moment.tz(TZ).add(-2, 'day').format('YYYY-MM-DD')
  const twoDaysAgoDay = partialPastDays.find(day => day[0] === twoDaysAgoDate)
  expect(twoDaysAgoDay).toBeDefined()
  expect(twoDaysAgoDay[1].some(item => item.id === 'new past partial')).toBe(true)
})

it('adds a new item to partial future days when the new date is before the near future boundary but outside loaded range', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0)]),
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: false,
      partialPastDays: [],
      partialFutureDays: itemsToDays([itemIdAt('existing future partial +3', 3)]),
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('new future partial', 2)},
  })

  // Verify item was added to partial future days
  const partialFutureDays = nextState.loading.partialFutureDays
  const twoDaysForwardDate = moment.tz(TZ).add(2, 'day').format('YYYY-MM-DD')
  const twoDaysForwardDay = partialFutureDays.find(day => day[0] === twoDaysForwardDate)
  expect(twoDaysForwardDay).toBeDefined()
  expect(twoDaysForwardDay[1].some(item => item.id === 'new future partial')).toBe(true)
})

it('adds a new item to partial future days when the new date is within the partial future date range', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0)]),
    loading: {
      plannerLoaded: true,
      allPastItemsLoaded: false,
      allFutureItemsLoaded: false,
      partialPastDays: [],
      partialFutureDays: itemsToDays([
        itemIdAt('existing future partial +1', 1),
        itemIdAt('existing future partial +3', 3),
      ]),
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('new future partial', 2)},
  })

  // Verify item was added to partial future days
  const partialFutureDays = nextState.loading.partialFutureDays
  const twoDaysForwardDate = moment.tz(TZ).add(2, 'day').format('YYYY-MM-DD')
  const twoDaysForwardDay = partialFutureDays.find(day => day[0] === twoDaysForwardDate)
  expect(twoDaysForwardDay).toBeDefined()
  expect(twoDaysForwardDay[1].some(item => item.id === 'new future partial')).toBe(true)
})

it('does nothing when the date falls in the distant past', () => {
  const initialState = makeState({
    loading: {
      partialPastDays: itemsToDays([itemIdAt('existing past partial', -1)]),
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('should be ignored', -2)},
  })
  expectStateUnchanged(nextState, initialState)
})

it('does nothing when the date falls in the distant future', () => {
  const initialState = makeState({
    loading: {
      partialFutureDays: itemsToDays([itemIdAt('existing future partial', 1)]),
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('should be ignored', 2)},
  })
  expectStateUnchanged(nextState, initialState)
})

it('does nothing when date falls in distant past and there is no near past range', () => {
  const initialState = makeState()
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('should be ignored', -1)},
  })
  expectStateUnchanged(nextState, initialState)
})

it('does nothing when date falls in distant future and there is no near future range', () => {
  const initialState = makeState()
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('should be ignored', 1)},
  })
  expectStateUnchanged(nextState, initialState)
})

it('does nothing if partial past days are not loaded', () => {
  const initialState = makeState({
    loading: {
      partialPastDays: [],
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('should be ignored', -2)},
  })
  expectStateUnchanged(nextState, initialState)
})

it('does nothing if partial future days are not loaded', () => {
  const initialState = makeState({
    loading: {
      partialFutureDays: [],
    },
  })
  const nextState = reducer(initialState, {
    type: 'SAVED_PLANNER_ITEM',
    payload: {item: itemIdAt('should be ignored', 2)},
  })
  expectStateUnchanged(nextState, initialState)
})

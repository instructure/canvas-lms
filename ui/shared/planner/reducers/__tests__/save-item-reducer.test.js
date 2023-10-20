/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {itemsToDays} from '../../utilities/daysUtils'
import {savedPlannerItem} from '../../actions'
import reducer from '../save-item-reducer'

const TZ = 'UTC'

expect.extend({
  toMatchSnapshotAndBe(received, argument) {
    expect(received).toMatchSnapshot()
    expect(received).toBe(argument)
    return {pass: true}
  },

  toMatchSnapshotAndNotBe(received, argument) {
    expect(received).toMatchSnapshot()
    expect(received).not.toBe(argument)
    return {pass: true}
  },
})

beforeAll(() => {
  MockDate.set('2018-01-01', 0)
})

afterAll(() => {
  MockDate.reset()
})

function itemIdAt(id, daysFromToday = 0, overrides = {}) {
  const targetDate = moment.tz(TZ).add(daysFromToday, 'day')
  const targetBucket = targetDate.clone().startOf('day')
  return {
    id,
    uniqueId: id,
    title: id.toString(),
    date: targetDate,
    dateBucketMoment: targetBucket,
    ...overrides,
  }
}

function makeState(options = {}) {
  const days = options.days || itemsToDays([itemIdAt(0, 0)])
  const loadingOptions = options.loading || {}
  const loading = {
    plannerLoaded: true,
    partialPastDays: [],
    partialFutureDays: [],
    allPastItemsLoaded: false,
    allFutureItemsLoaded: false,
    ...loadingOptions,
  }
  return {days, loading}
}

it('does not return an initial state', () => {
  expect(reducer(undefined, savedPlannerItem({item: itemIdAt('ignore', 0)}))).not.toBeDefined()
})

it('does nothing if the action is not SAVED_PLANNER_ITEM', () => {
  const initialState = makeState()
  const action = savedPlannerItem({item: itemIdAt('failed to save', 0)})
  action.type = 'SOME_OTHER_ACTION'
  const nextState = reducer(initialState, action)
  expect(nextState).toMatchSnapshotAndBe(initialState)
})

it('does nothing if action.error', () => {
  const initialState = makeState()
  const action = savedPlannerItem({item: itemIdAt('failed to save', 0)})
  action.error = true
  const nextState = reducer(initialState, action)
  expect(nextState).toMatchSnapshotAndBe(initialState)
})

it('does nothing if the planner is not loaded', () => {
  const initialState = makeState({loading: {plannerLoaded: false}})
  const action = savedPlannerItem({item: itemIdAt('blah', 0)})
  const nextState = reducer(initialState, action)
  expect(nextState).toMatchSnapshotAndBe(initialState)
})

it('adds a new item to a new day when the new date is within the loaded range', () => {
  const initialState = makeState({days: itemsToDays([itemIdAt(0, 0), itemIdAt(2, 2)])})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt(1, 1)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds a new item to an existing day when the new date is within the loaded range', () => {
  const initialState = makeState({days: itemsToDays([itemIdAt(0, 0), itemIdAt(1, 0)])})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt(2, 0)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds an item to today even when the only loaded items are in the future', () => {
  const initialState = makeState({days: itemsToDays([itemIdAt(1, 1)])})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt(0, 0)}))
  expect(nextState.days).toHaveLength(2)
})

it('adds a new item to a new day when the loaded range is open ended in the past', () => {
  const initialState = makeState({
    loading: {allPastItemsLoaded: true},
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new past', -1)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds a new item to a new day when the loaded range is open ended in the future', () => {
  const initialState = makeState({
    loading: {allFutureItemsLoaded: true},
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new future', 1)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds a new item to partial past days when the new date matches the near past boundary', () => {
  const initialState = makeState({
    loading: {
      partialPastDays: itemsToDays([itemIdAt('existing past partial', -1)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('new past partial', -1)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds a new item to partial past days when the new date is after the near past boundary but outside loaded range', () => {
  const initialState = makeState({
    loading: {
      partialPastDays: itemsToDays([itemIdAt('existing past partial -3', -3)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('new past partial', -2)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds a new item to partial past days when the new date is within the partial past date range', () => {
  const initialState = makeState({
    loading: {
      partialPastDays: itemsToDays([
        itemIdAt('existing past partial -3', -3),
        itemIdAt('existing past partial -1', -1),
      ]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('new past partial', -2)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds a new item to partial future days when the new date matches the near future boundary', () => {
  const initialState = makeState({
    loading: {
      partialFutureDays: itemsToDays([itemIdAt('existing future partial', 1)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('new future partial', 1)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds a new item to partial future days when the new date is before the near future boundary but outside loaded range', () => {
  const initialState = makeState({
    loading: {
      partialFutureDays: itemsToDays([itemIdAt('existing future partial +3', 3)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('new future partial', 2)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('adds a new item to partial future days when the new date is within the partial future date range', () => {
  const initialState = makeState({
    loading: {
      partialFutureDays: itemsToDays([
        itemIdAt('existing future partial +1', 1),
        itemIdAt('existing future partial +3', 3),
      ]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('new future partial', 2)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('does nothing when the date falls in the distant past', () => {
  const initialState = makeState({
    loading: {
      partialPastDays: itemsToDays([itemIdAt('existing past partial', -1)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('should be ignored', -2)})
  )
  expect(nextState).toMatchSnapshotAndBe(initialState)
})

it('does nothing when the date falls in the distant future', () => {
  const initialState = makeState({
    loading: {
      partialFutureDays: itemsToDays([itemIdAt('existing future partial', 1)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('should be ignored', 2)})
  )
  expect(nextState).toMatchSnapshotAndBe(initialState)
})

it('does nothing when date falls in distant past and there is no near past range', () => {
  const initialState = makeState()
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('should be ignored', -1)})
  )
  expect(nextState).toMatchSnapshotAndBe(initialState)
})

it('does nothing when date falls in distant future and there is no near future range', () => {
  const initialState = makeState()
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('should be ignored', 1)})
  )
  expect(nextState).toMatchSnapshotAndBe(initialState)
})

it('removes item from days and adds it to partial past days when the date has changed to a near past date', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('should be in partial past', -1)]),
    loading: {
      partialPastDays: itemsToDays([itemIdAt(-2, -2)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('should be in partial past', -2)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('removes item from days and adds it to partial future days when the date has changed to a near future date', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('should be in partial future', -1)]),
    loading: {
      partialFutureDays: itemsToDays([itemIdAt(2, 2)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('should be in partial future', 2)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('removes item from days when the date has changed to a distant past date', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(-1, -1), itemIdAt('should be removed', 0)]),
    loading: {
      partialPastDays: itemsToDays([itemIdAt(-2, -2)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('should be removed', -3)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('removes item from days when the date has changed to a distant future date', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('should be removed', 1)]),
    loading: {
      partialFutureDays: itemsToDays([itemIdAt(2, 2)]),
    },
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({item: itemIdAt('should be removed', 3)})
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('changes the date to an existing day when the date has changed within the loaded range', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('to move', 0), itemIdAt(1, 1), itemIdAt(2, 1)]),
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('to move', 1)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('changes the date to a new day when the date has changed within the loaded range', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('to move', 0), itemIdAt(2, 2)]),
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('to move', 1)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('updates the item when its date does not change', () => {
  const initialState = makeState({
    days: itemsToDays([itemIdAt(0, 0), itemIdAt('to update', 0)]),
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({
      item: itemIdAt('to update', 0, {title: 'updated title'}),
    })
  )
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('inserts a today item into days if the state is empty', () => {
  const initialState = makeState({days: []})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new item', 0)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('inserts a future item into days if the state is empty and allFutureItemsLoaded', () => {
  const initialState = makeState({days: [], loading: {allFutureItemsLoaded: true}})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new item', 1)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('inserts a past item into days if state is empty and allPastItemsLoaded', () => {
  const initialState = makeState({days: [], loading: {allPastItemsLoaded: true}})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('new item', -1)}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('does not insert a past item into days if the state is empty and past is not loaded', () => {
  const initialState = makeState({days: []})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt('ignore item', -1)}))
  expect(nextState).toMatchSnapshotAndBe(initialState)
})

it('inserts an item into last loaded day even when it is after startOf("day")', () => {
  const initialState = makeState({days: itemsToDays([itemIdAt(0, 0), itemIdAt(1, 1)])})
  const item = itemIdAt('afternoon item', 1)
  item.dateBucketMoment.add(13, 'hours')
  const nextState = reducer(initialState, savedPlannerItem({item}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

it('resorts the order of items when the item date has not changed', () => {
  const initialState = makeState({
    days: itemsToDays([
      itemIdAt(0, 0, {title: 'aaa'}),
      itemIdAt(1, 0, {title: 'bbb'}),
      itemIdAt(2, 0, {title: 'ccc'}),
    ]),
  })
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt(1, 0, {title: 'eee'})}))
  expect(nextState).toMatchSnapshotAndNotBe(initialState)
})

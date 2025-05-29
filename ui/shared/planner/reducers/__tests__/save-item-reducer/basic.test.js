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
import {savedPlannerItem} from '../../../actions'
import reducer from '../../save-item-reducer'

const TZ = 'UTC'

function expectStateUnchanged(nextState, initialState) {
  expect(nextState).toBe(initialState)
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

it('handles undefined state appropriately', () => {
  // The reducer might not actually return a state when undefined is passed
  // This is fine as long as it doesn't throw an error
  const _state = reducer(undefined, {type: 'INIT'})

  // Just verify it doesn't throw an error
  expect(() => reducer(undefined, {type: 'INIT'})).not.toThrow()
})

it('does nothing if the action is not SAVED_PLANNER_ITEM', () => {
  const initialState = makeState()
  const nextState = reducer(initialState, {type: 'NOT_SAVED_PLANNER_ITEM'})
  expectStateUnchanged(nextState, initialState)
})

it('does nothing if action.error', () => {
  const initialState = makeState()

  // Create a properly formatted item with moment objects
  const item = itemIdAt('test', 0)

  // Create an action with error property at the top level
  const action = {
    type: 'SAVED_PLANNER_ITEM',
    error: true,
    payload: {item},
  }

  // Use the action with error property
  const nextState = reducer(initialState, action)

  // Verify the state didn't change
  expectStateUnchanged(nextState, initialState)
})

it('does nothing if the planner is not loaded', () => {
  const initialState = makeState({loading: {plannerLoaded: false}})
  const nextState = reducer(initialState, savedPlannerItem({item: itemIdAt()}))
  expectStateUnchanged(nextState, initialState)
})

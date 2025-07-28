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
// Not used in this file but kept for consistency with other test files
function _expectStateUnchanged(nextState, initialState) {
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

// Not used in this file but kept for consistency with other test files
function _itemIdAt(id = 0, daysOffset = 0) {
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

it('resorts the order of items when the item date has not changed', () => {
  const initialState = makeState({
    days: itemsToDays([
      {
        id: 'aaa',
        uniqueId: 'aaa',
        date: moment.tz(TZ).clone(),
        dateBucketMoment: moment.tz(TZ).clone(),
        title: 'aaa',
      },
      {
        id: 'ccc',
        uniqueId: 'ccc',
        date: moment.tz(TZ).clone(),
        dateBucketMoment: moment.tz(TZ).clone(),
        title: 'ccc',
      },
      {
        id: 'eee',
        uniqueId: 'eee',
        date: moment.tz(TZ).clone(),
        dateBucketMoment: moment.tz(TZ).clone(),
        title: 'eee',
      },
    ]),
  })
  const nextState = reducer(
    initialState,
    savedPlannerItem({
      item: {
        id: 'eee',
        uniqueId: 'eee',
        date: moment.tz(TZ).clone(),
        dateBucketMoment: moment.tz(TZ).clone(),
        title: 'eee',
      },
    }),
  )
  expectStateChanged(nextState, initialState)

  // Verify items are still in order
  const todayDate = moment.tz(TZ).format('YYYY-MM-DD')
  const todayDay = nextState.days.find(day => day[0] === todayDate)
  expect(todayDay).toBeDefined()
  const todayItems = todayDay[1]
  // Verify items are in the expected order
  const titles = todayItems.map(item => item.title)
  expect(titles).toEqual(['aaa', 'ccc', 'eee'])
})

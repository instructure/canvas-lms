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

import moment from 'moment-timezone'
import MockDate from 'mockdate'
import {
  mergeFutureItems,
  mergePastItems,
  mergePastItemsForNewActivity,
  mergePastItemsForToday,
  consumePeekIntoPast,
  mergeWeekItems,
} from '../saga-actions'
import {
  gotPartialFutureDays,
  gotPartialPastDays,
  gotDaysSuccess,
  peekedIntoPast,
  gotPartialWeekDays,
  weekLoaded,
} from '../loading-actions'
import {itemsToDays} from '../../utilities/daysUtils'

function getStateFn(opts = {loading: {}}) {
  return () => ({
    loading: {
      isLoading: false,
      allFutureItemsLoaded: false,
      partialFutureDays: [],

      allPastItemsLoaded: false,
      partialPastDays: [],
      ...opts.loading,
    },
  })
}

function mockItem(date = '2017-12-18', opts = {}) {
  return {
    dateBucketMoment: date,
    newActivity: false,
    ...opts,
  }
}

describe('mergeFutureItems', () => {
  it('extracts and dispatches complete days and returns true', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-18'), mockItem('2017-12-18'), mockItem('2017-12-19')]
    const mockDays = itemsToDays(mockItems)
    const result = mergeFutureItems(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialFutureDays: mockDays}})
    )
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialFutureDays(mockDays, 'mock response'))
    expect(mockDispatch).toHaveBeenCalledWith(
      gotDaysSuccess(itemsToDays([mockItems[0], mockItems[1]]), 'mock response')
    )
  })

  it('does not dispatch gotDaysSuccess if there are no complete days and returns false', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem(), mockItem()]
    const result = mergeFutureItems(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialFutureDays: itemsToDays(mockItems)}})
    )
    expect(result).toBe(false)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialFutureDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledTimes(1)
  })

  it('extracts all days when allFutureItemsLoaded', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem(), mockItem()]
    const result = mergeFutureItems(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialFutureDays: itemsToDays(mockItems), allFutureItemsLoaded: true}})
    )
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialFutureDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledWith(
      gotDaysSuccess(itemsToDays(mockItems), 'mock response')
    )
  })

  it('returns true when allFutureItemsLoaded but there are no available days', () => {
    const mockDispatch = jest.fn()
    const mockItems = []
    const result = mergeFutureItems(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialFutureDays: [], allFutureItemsLoaded: true}})
    )
    expect(result).toBe(true)
    // still want to pretend something was loaded so all the loading states get updated.
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialFutureDays([], 'mock response'))
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess([], 'mock response'))
  })
})

describe('mergePastItems', () => {
  it('extracts complete days in reverse order', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-17'), mockItem('2017-12-18')]
    const result = mergePastItems(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}})
    )
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledWith(
      gotDaysSuccess(itemsToDays([mockItems[1]]), 'mock response')
    )
  })

  it('extracts all days when allPastItemsLoaded', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem(), mockItem()]
    const result = mergePastItems(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems), allPastItemsLoaded: true}})
    )
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledWith(
      gotDaysSuccess(itemsToDays(mockItems), 'mock response')
    )
  })

  it('returns true when allPastItemsLoaded but there are no available days', () => {
    const mockDispatch = jest.fn()
    const mockItems = []
    const result = mergePastItems(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: [], allPastItemsLoaded: true}})
    )
    expect(result).toBe(true)
    // still want to pretend something was loaded so all the loading states get updated.
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialPastDays([], 'mock response'))
    expect(mockDispatch).toHaveBeenCalledWith(gotDaysSuccess([], 'mock response'))
  })
})

describe('mergePastItemsForNewActivity', () => {
  it('does not merge complete days if there is no new activity in those days', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-17'), mockItem('2017-12-18')]
    const result = mergePastItemsForNewActivity(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}})
    )
    expect(result).toBe(false)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledTimes(1)
  })

  it('does not merge partial days even with new activity', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-18', {newActivity: true})]
    const result = mergePastItemsForNewActivity(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}})
    )
    expect(result).toBe(false)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledTimes(1)
  })

  it('merges days if allPastItemsLoaded even if no new activity', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-18')]
    const result = mergePastItemsForNewActivity(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems), allPastItemsLoaded: true}})
    )
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledWith(
      gotDaysSuccess(itemsToDays(mockItems), 'mock response')
    )
  })

  it('merges complete days when they contain new activity', () => {
    const mockDispatch = jest.fn()
    const mockItems = [
      mockItem('2017-12-17'),
      mockItem('2017-12-18', {newActivity: true}),
      mockItem('2017-12-18'),
    ]
    const result = mergePastItemsForNewActivity(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}})
    )
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledWith(
      gotDaysSuccess(itemsToDays([mockItems[1], mockItems[2]]), 'mock response')
    )
  })
})

describe('mergePastItemsForToday', () => {
  beforeAll(() => {
    MockDate.set('2017-12-22')
  })

  afterAll(() => {
    MockDate.reset()
  })

  it('does not merge complete days if we did not find today', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-23'), mockItem('2017-12-24')]
    const result = mergePastItemsForToday(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}})
    )
    expect(result).toBe(false)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledTimes(1)
  })

  it('does not merge partial days even finding today', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-18')]
    const result = mergePastItemsForToday(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}})
    )
    expect(result).toBe(false)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledTimes(1)
  })

  it('merges days if allPastItemsLoaded even if we did not find today', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-14')]
    const result = mergePastItemsForToday(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems), allPastItemsLoaded: true}})
    )
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledWith(
      gotDaysSuccess(itemsToDays(mockItems), 'mock response')
    )
  })

  it('merges complete days when they contain today', () => {
    const mockDispatch = jest.fn()
    const mockItems = [mockItem('2017-12-15'), mockItem('2017-12-16')]
    const result = mergePastItemsForToday(mockItems, 'mock response')(
      mockDispatch,
      getStateFn({loading: {partialPastDays: itemsToDays(mockItems)}})
    )
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialPastDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledWith(
      gotDaysSuccess(itemsToDays([mockItems[1]]), 'mock response')
    )
  })
})

describe('consumePeekIntoPast', () => {
  it('found a past item', () => {
    const mockDispatch = jest.fn()
    const result = consumePeekIntoPast(['item'], 'mock response')(mockDispatch, () => {})
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(peekedIntoPast({hasSomeItems: true}))
  })
  it('found no past items', () => {
    const mockDispatch = jest.fn()
    const result = consumePeekIntoPast([], 'mock response')(mockDispatch, () => {})
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(peekedIntoPast({hasSomeItems: false}))
  })
})

describe('mergeWeekItems', () => {
  let getStateMock
  beforeAll(() => {
    MockDate.set('2021-03-07') // a Sunday
  })

  afterAll(() => {
    MockDate.reset()
  })

  beforeEach(() => {
    getStateMock = jest.fn(opts => {
      return {
        ...getStateFn(opts)(),
        weeklyDashboard: {
          weekStart: moment.tz('UTC').startOf('week'),
          weekEnd: moment.tz('UTC').endOf('week'),
          weeks: [],
        },
      }
    })
  })

  it('extracts and dispatches complete days and returns true', () => {
    const mockDispatch = jest.fn()
    const mockItems = []
    const sunday = moment.tz('UTC').startOf('week')
    for (let i = 0; i < 8; ++i) {
      mockItems.push(mockItem(sunday.clone().add(i, 'days').format()))
    }
    const mockDays = itemsToDays(mockItems)
    const result = mergeWeekItems()(mockItems, 'mock response')(mockDispatch, () => {
      return {
        ...getStateMock({
          loading: {partialWeekDays: mockDays, allWeekItemsLoaded: true},
        }),
      }
    })
    expect(result).toBe(true)
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialWeekDays(mockDays, 'mock response'))
    expect(mockDispatch).toHaveBeenCalledWith(
      weekLoaded(
        {
          initialWeeklyLoad: false,
          weekDays: itemsToDays(mockItems),
          weekStart: sunday,
          isPreload: false,
        },
        'mock response'
      )
    )
  })

  it('does not dispatch weekLoaded we do not get the full week up front', () => {
    const mockDispatch = jest.fn()
    const mockItems = []
    const sunday = moment.tz('UTC').startOf('week')
    for (let i = 0; i < 5; ++i) {
      mockItems.push(mockItem(sunday.clone().add(i, 'days').format()))
    }
    const mockDays = itemsToDays(mockItems)
    const result = mergeWeekItems()(mockItems, 'mock response')(mockDispatch, () => {
      return {
        ...getStateMock(),
        loading: {partialWeekDays: mockDays, allWeekItemsLoaded: false},
      }
    })
    expect(result).toBe(false)
    expect(mockDispatch).toHaveBeenCalledWith(
      gotPartialWeekDays(itemsToDays(mockItems), 'mock response')
    )
    expect(mockDispatch).toHaveBeenCalledTimes(1)
  })

  it('returns true when allWeekItemsLoaded but there are no available days', () => {
    const mockDispatch = jest.fn()
    const mockItems = []
    const sunday = moment.tz('UTC').startOf('week')
    const result = mergeWeekItems()(mockItems, 'mock response')(mockDispatch, () => {
      return {
        ...getStateMock({
          loading: {partialWeekDays: [], allWeekItemsLoaded: true},
        }),
      }
    })
    expect(result).toBe(true)
    // still want to pretend something was loaded so all the loading states get updated.
    expect(mockDispatch).toHaveBeenCalledWith(gotPartialWeekDays([], 'mock response'))
    expect(mockDispatch).toHaveBeenCalledWith(
      weekLoaded(
        {initialWeeklyLoad: false, weekDays: [], weekStart: sunday, isPreload: false},
        'mock response'
      )
    )
  })
})

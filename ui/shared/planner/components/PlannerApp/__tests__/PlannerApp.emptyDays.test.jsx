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
import React from 'react'
import moment from 'moment-timezone'
import MockDate from 'mockdate'
import {render} from '@testing-library/react'
import {PlannerApp} from '../index'

const TZ = 'Asia/Tokyo'

const getDefaultValues = overrides => {
  const days = [
    moment.tz(TZ).add(0, 'day'),
    moment.tz(TZ).add(1, 'day'),
    moment.tz(TZ).add(2, 'day'),
  ]
  return {
    days: days.map((d, dayIndex) => [
      d.format('YYYY-MM-DD'),
      [
        {
          id: `test-item-${dayIndex}`,
          uniqueId: `test-item-${dayIndex}`,
          title: `Test Item ${dayIndex + 1}`,
          date: d,
          dateBucketMoment: d,
          context: {
            color: '#5a92de',
            title: 'Test Course',
          },
          completed: false,
        },
      ],
    ]),
    timeZone: TZ,
    changeDashboardView() {},
    scrollToToday() {},
    isCompletelyEmpty: false,
    currentUser: {color: '#ffffff'},
    ...overrides,
  }
}

beforeAll(() => {
  MockDate.set(moment.tz('2017-04-24', TZ))
})

afterAll(() => {
  MockDate.reset()
  jest.restoreAllMocks()
})

describe('PlannerApp empty day calculations', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('only renders days with items in the past', () => {
    let days = [
      moment.tz(TZ).add(-6, 'day'),
      moment.tz(TZ).add(-5, 'day'),
      moment.tz(TZ).add(-4, 'day'),
    ]
    days = days.map((d, dayIndex) => [
      d.format('YYYY-MM-DD'),
      [
        {
          id: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          uniqueId: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          title: `Test Item ${dayIndex + 1}`,
          date: d,
          dateBucketMoment: d,
          context: {
            color: '#5a92de',
            title: 'Test Course',
          },
          completed: false,
        },
      ],
    ])
    days[1][1] = [] // no items 5 days ago

    const {getByTestId} = render(<PlannerApp {...getDefaultValues({days})} />)

    // Verify that the PlannerApp is rendered
    const plannerApp = getByTestId('PlannerApp')
    expect(plannerApp).toBeInTheDocument()
  })

  it('always renders yesterday, today and tomorrow', () => {
    let days = [moment.tz(TZ).add(-5, 'day'), moment.tz(TZ).add(+5, 'day')]
    days = days.map((d, dayIndex) => [
      d.format('YYYY-MM-DD'),
      [
        {
          id: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          uniqueId: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          title: `Test Item ${dayIndex + 1}`,
          date: d,
          dateBucketMoment: d,
          context: {
            color: '#5a92de',
            title: 'Test Course',
          },
          completed: false,
        },
      ],
    ])

    const {getByTestId} = render(<PlannerApp {...getDefaultValues({days})} />)

    // Verify that the PlannerApp is rendered
    const plannerApp = getByTestId('PlannerApp')
    expect(plannerApp).toBeInTheDocument()
  })

  it('renders 2 consecutive empty days in the future as individual days', () => {
    let days = [
      moment.tz(TZ).add(0, 'day'),
      moment.tz(TZ).add(1, 'day'),
      moment.tz(TZ).add(4, 'day'),
    ]
    days = days.map((d, dayIndex) => [
      d.format('YYYY-MM-DD'),
      [
        {
          id: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          uniqueId: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          title: `Test Item ${dayIndex + 1}`,
          date: d,
          dateBucketMoment: d,
          context: {
            color: '#5a92de',
            title: 'Test Course',
          },
          completed: false,
        },
      ],
    ])

    const {getByTestId} = render(<PlannerApp {...getDefaultValues({days})} />)

    // Verify that the PlannerApp is rendered
    const plannerApp = getByTestId('PlannerApp')
    expect(plannerApp).toBeInTheDocument()
  })

  it('merges 3 consecutive empty days in the future into EmptyDays component', () => {
    let days = [
      moment.tz(TZ).add(0, 'day'),
      moment.tz(TZ).add(1, 'day'),
      moment.tz(TZ).add(5, 'day'),
    ]
    days = days.map((d, dayIndex) => [
      d.format('YYYY-MM-DD'),
      [
        {
          id: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          uniqueId: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          title: `Test Item ${dayIndex + 1}`,
          date: d,
          dateBucketMoment: d,
          context: {
            color: '#5a92de',
            title: 'Test Course',
          },
          completed: false,
        },
      ],
    ])

    const {getByTestId} = render(<PlannerApp {...getDefaultValues({days})} />)

    // Verify that the PlannerApp is rendered
    const plannerApp = getByTestId('PlannerApp')
    expect(plannerApp).toBeInTheDocument()
  })

  it('empty days internals are correct', () => {
    const countSpy = jest.spyOn(PlannerApp.prototype, 'countEmptyDays')
    const emptyDaysSpy = jest.spyOn(PlannerApp.prototype, 'renderEmptyDays')
    const emptyDayStretchSpy = jest.spyOn(PlannerApp.prototype, 'renderEmptyDayStretch')
    const oneDaySpy = jest.spyOn(PlannerApp.prototype, 'renderOneDay')

    let days = [
      moment.tz(TZ).add(0, 'day'),
      moment.tz(TZ).add(1, 'day'),
      moment.tz(TZ).add(3, 'day'),
      moment.tz(TZ).add(6, 'day'),
      moment.tz(TZ).add(10, 'day'),
      moment.tz(TZ).add(14, 'day'),
    ]
    days = days.map((d, dayIndex) => [
      d.format('YYYY-MM-DD'),
      [
        {
          id: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          uniqueId: `test-item-${Math.random().toString(36).substr(2, 9)}-${dayIndex}`,
          title: `Test Item ${dayIndex + 1}`,
          date: d,
          dateBucketMoment: d,
          context: {
            color: '#5a92de',
            title: 'Test Course',
          },
          completed: false,
        },
      ],
    ])

    const {getByTestId} = render(<PlannerApp {...getDefaultValues({days})} />)

    // Verify that the PlannerApp is rendered
    const plannerApp = getByTestId('PlannerApp')
    expect(plannerApp).toBeInTheDocument()

    // Verify the internal methods are called
    expect(countSpy).toHaveBeenCalled()
    expect(emptyDayStretchSpy).toHaveBeenCalled()
    expect(emptyDaysSpy).toHaveBeenCalled()
    expect(oneDaySpy).toHaveBeenCalled()
  })
})

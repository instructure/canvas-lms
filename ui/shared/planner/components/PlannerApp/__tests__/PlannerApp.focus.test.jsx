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
    days: days.map((d, index) => [
      d.format('YYYY-MM-DD'),
      [
        {
          dateBucketMoment: d,
          context: {
            color: '#5a92de',
            title: 'Test Course',
          },
          items: [
            {
              id: `item-${index}`,
              uniqueId: `item-${index}`,
              title: `Test Item ${index}`,
              date: d,
              context: {
                color: '#5a92de',
                title: 'Test Course',
              },
            },
          ],
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

describe('PlannerApp focus handling', () => {
  const originalActiveElement = document.activeElement
  let containerElement = null

  beforeEach(() => {
    containerElement = document.createElement('div')
    document.body.appendChild(containerElement)
  })

  afterEach(() => {
    if (originalActiveElement) originalActiveElement.focus()
    if (containerElement) document.body.removeChild(containerElement)
    jest.clearAllMocks()
  })

  it('calls fallbackFocus when the load prior focus button disappears', () => {
    const focusFallback = jest.fn()

    // Render with allPastItemsLoaded=false to show the load prior button
    const {rerender, getByText} = render(
      <PlannerApp
        {...getDefaultValues()}
        days={[]}
        allPastItemsLoaded={false}
        focusFallback={focusFallback}
        currentUser={{color: '#ffffff'}}
      />,
      {container: containerElement},
    )

    // Find and focus the load prior button
    const loadButton = getByText('Load prior dates')
    loadButton.focus()

    // Re-render with allPastItemsLoaded=true to hide the button
    rerender(
      <PlannerApp
        {...getDefaultValues()}
        days={[]}
        allPastItemsLoaded={true}
        focusFallback={focusFallback}
      />,
    )

    // Verify the focus fallback was called
    expect(focusFallback).toHaveBeenCalled()
  })

  it('maintains focus when items are loaded', () => {
    const mockScrollToToday = jest.fn()

    // Render with initial state
    const {rerender} = render(
      <PlannerApp {...getDefaultValues()} scrollToToday={mockScrollToToday} />,
      {container: containerElement},
    )

    // Re-render with new days to simulate loading more items
    const newDays = [
      ...getDefaultValues().days,
      [
        moment.tz(TZ).add(3, 'day').format('YYYY-MM-DD'),
        [{dateBucketMoment: moment.tz(TZ).add(3, 'day')}],
      ],
    ]

    rerender(
      <PlannerApp {...getDefaultValues({days: newDays})} scrollToToday={mockScrollToToday} />,
    )

    // The component should maintain focus and not trigger scrollToToday
    // when just adding new days
    expect(mockScrollToToday).not.toHaveBeenCalled()
  })

  it('triggers dynamic UI updates after props change', () => {
    const mockTriggerUpdates = jest.fn()

    // Render with isLoading=true
    const {rerender} = render(
      <PlannerApp
        {...getDefaultValues({isLoading: true})}
        triggerDynamicUiUpdates={mockTriggerUpdates}
      />,
      {container: containerElement},
    )

    // Re-render with isLoading=false to trigger componentDidUpdate
    rerender(
      <PlannerApp
        {...getDefaultValues({isLoading: false})}
        triggerDynamicUiUpdates={mockTriggerUpdates}
      />,
    )

    // Verify the dynamic UI updates were triggered
    expect(mockTriggerUpdates).toHaveBeenCalledTimes(1)
  })
})

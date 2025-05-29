/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
    days: days.map(d => [
      d.format('YYYY-MM-DD'),
      [
        {
          dateBucketMoment: d,
          context: {
            color: '#5a92de',
            title: 'Test Course',
          },
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

describe('PlannerApp basic rendering', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders base component with days', () => {
    const {getByTestId} = render(<PlannerApp {...getDefaultValues()} />)

    // Should render the PlannerApp container
    const plannerApp = getByTestId('PlannerApp')
    expect(plannerApp).toBeInTheDocument()

    // Should have the correct class
    expect(plannerApp).toHaveClass('PlannerApp')
  })

  it('renders empty component with no assignments', () => {
    const opts = getDefaultValues()
    opts.days = []
    opts.isCompletelyEmpty = true
    const {container, getByText} = render(<PlannerApp {...opts} />)

    // Should render the empty state with desert image when completely empty
    expect(container.querySelector('.desert')).toBeInTheDocument()
    expect(getByText('No Due Dates Assigned')).toBeInTheDocument()
    expect(getByText("Looks like there isn't anything here")).toBeInTheDocument()
  })

  it('shows load prior items button when there is more to load', () => {
    const {getByText} = render(<PlannerApp {...getDefaultValues()} />)

    // Should render the load prior items button
    const loadButton = getByText('Load prior dates')
    expect(loadButton).toBeInTheDocument()
  })

  it('does not show load prior items button when all past items are loaded', () => {
    const {queryByText} = render(<PlannerApp {...getDefaultValues()} allPastItemsLoaded={true} />)

    // Should not render the load prior items button
    const loadButton = queryByText('Load prior dates')
    expect(loadButton).not.toBeInTheDocument()
  })

  it('notifies the UI to perform dynamic updates', () => {
    const mockUpdate = jest.fn()
    const {rerender} = render(
      <PlannerApp {...getDefaultValues({isLoading: true})} triggerDynamicUiUpdates={mockUpdate} />,
    )

    // Rerender with isLoading set to false to trigger componentDidUpdate
    rerender(
      <PlannerApp {...getDefaultValues({isLoading: false})} triggerDynamicUiUpdates={mockUpdate} />,
    )

    // Should call the update function
    expect(mockUpdate).toHaveBeenCalledTimes(1)
  })
})

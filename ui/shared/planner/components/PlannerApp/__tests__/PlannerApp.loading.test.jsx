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
          uniqueId: `test-item-${index}`,
          title: `Test Assignment ${index + 1}`,
          id: `assignment-${index}`,
          type: 'assignment',
          date: d.toISOString(),
          completed: false,
          context: {
            id: 'test-course-1',
            type: 'Course',
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

describe('PlannerApp loading states', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('shows only the loading component when the isLoading prop is true', () => {
    const {container} = render(<PlannerApp {...getDefaultValues()} isLoading={true} />)

    // The spinner is rendered inside the component
    // We can verify loading state by checking that the PlannerApp exists but no Day components are rendered
    expect(container.querySelector('[data-testid="PlannerApp"]')).toBeInTheDocument()
    expect(container.querySelector('.Day')).not.toBeInTheDocument()
  })

  it('shows the loading past indicator when loadingPast prop is true', () => {
    const {container, getByTestId} = render(
      <PlannerApp {...getDefaultValues()} loadingPast={true} />,
    )

    // Verify that the PlannerApp is rendered
    const plannerApp = getByTestId('PlannerApp')
    expect(plannerApp).toBeInTheDocument()

    // The loading indicator is rendered, but we can't reliably query for specific elements
    // Instead, we can check that the component is rendered and contains a spinner
    const spinner = container.querySelector('svg')
    expect(spinner).toBeInTheDocument()
  })

  it('renders loading past spinner when loading past and there are no future items', () => {
    const {container} = render(
      <PlannerApp
        days={[]}
        timeZone="UTC"
        changeDashboardView={() => {}}
        firstNewActivityDate={moment().add(-1, 'days')}
        loadingPast={true}
        currentUser={{color: '#ffffff'}}
        onAddToDo={() => {}}
      />,
    )

    // Should render the loading past indicator with a spinner
    const spinner = container.querySelector('svg[role="img"]')
    expect(spinner).toBeInTheDocument()
  })

  it('shows loading future indicator when loadingFuture prop is true', () => {
    const {container, getByTestId} = render(
      <PlannerApp {...getDefaultValues()} loadingFuture={true} />,
    )

    // Verify that the PlannerApp is rendered
    const plannerApp = getByTestId('PlannerApp')
    expect(plannerApp).toBeInTheDocument()

    // We can verify the loading future indicator is rendered by checking for the fixed element
    // which is present when loading future items
    const fixedElement = container.querySelector('#planner-app-fixed-element')
    expect(fixedElement).toBeInTheDocument()
  })

  it('shows empty state when no items and not loading', () => {
    const {getByText} = render(
      <PlannerApp
        days={[]}
        timeZone={TZ}
        changeDashboardView={() => {}}
        isCompletelyEmpty={true}
        currentUser={{color: '#ffffff'}}
        onAddToDo={() => {}}
      />,
    )

    // Should render the empty state with the correct text
    expect(getByText('No Due Dates Assigned')).toBeInTheDocument()
    expect(getByText("Looks like there isn't anything here")).toBeInTheDocument()
  })
})

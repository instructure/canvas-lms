/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
// import {shallow, mount} from 'enzyme'
import {render} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import {PlannerApp, mapStateToProps} from '../index'

const TZ = 'Asia/Tokyo'

const getDefaultValues = overrides => {
  const thisWeekStart = moment.tz(TZ).startOf('week')
  const thisWeekEnd = moment.tz(TZ).endOf('week')

  return {
    currentUser: {
      avatarUrl: '/images/thumbnails/2',
      color: 'blue',
      displayName: 'The Student',
      id: '2',
    },
    days: [],
    timeZone: TZ,
    isWeekly: true,
    changeDashboardView() {},
    scrollToToday() {},
    isCompletelyEmpty: false,
    weeklyDashboard: {
      weekStart: thisWeekStart,
      weekEnd: thisWeekEnd,
      thisWeek: thisWeekStart,
      weeks: {},
    },
    thisWeek: {
      weekStart: thisWeekStart,
      weekEnd: thisWeekEnd,
    },
    weekLoaded: true,
    loadingOpportunities: false,
    opportunityCount: 0,
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

describe('Weekly PlannerApp', () => {
  it('renders empty days with no assignments this week', () => {
    const opts = getDefaultValues()
    const {queryAllByText} = render(<PlannerApp {...opts} />)
    expect(queryAllByText('Nothing Planned Yet').length).toEqual(7)
    const d = opts.thisWeek.weekStart.clone()
    for (let i = 0; i < 7; ++i) {
      const dstr = d.format('MMMM D')
      expect(queryAllByText(dstr, {exact: false})[0]).toBeInTheDocument()
      d.add(1, 'day')
    }
  })

  it('renders empty days with no assignments some other week', () => {
    const nextWeekStart = moment.tz(TZ).startOf('week').add(7, 'days')
    const nextWeekEnd = moment.tz(TZ).endOf('week').add(7, 'days')
    const opts = getDefaultValues({
      weeklyDashboard: {
        weekStart: nextWeekStart,
        weekEnd: nextWeekEnd,
        thisWeek: nextWeekStart,
        weeks: {},
      },
      thisWeek: {
        weekStart: nextWeekStart,
        weekEnd: nextWeekEnd,
      },
    })
    const {queryAllByText} = render(<PlannerApp {...opts} />)
    expect(queryAllByText('Nothing Planned Yet').length).toEqual(7)
    const d = opts.thisWeek.weekStart.clone()
    for (let i = 0; i < 7; ++i) {
      const dstr = d.format('MMMM D')
      expect(queryAllByText(dstr, {exact: false})[0]).toBeInTheDocument()
      d.add(1, 'day')
    }
  })

  it('displays the whole week if there are any items', () => {
    const opts = getDefaultValues()
    let days = [opts.thisWeek.weekStart.clone().add(1, 'day')]
    days = days.map(d => [
      d.format('YYYY-MM-DD'),
      [{dateBucketMoment: d, uniqueId: '1', title: ''}],
    ])
    const {container, queryAllByText} = render(<PlannerApp {...getDefaultValues({days})} />)
    expect(container.querySelectorAll('.planner-day').length).toEqual(7)
    const d = opts.thisWeek.weekStart.clone()
    for (let i = 0; i < 7; ++i) {
      const dstr = d.format('MMMM D')
      expect(queryAllByText(dstr, {exact: false})[0]).toBeInTheDocument()
      d.add(1, 'day')
    }
  })

  it('shows only the loading component when the weekLoaded prop is false', () => {
    const {getByText} = render(<PlannerApp {...getDefaultValues()} weekLoaded={false} />)
    expect(getByText('Loading planner items')).toBeInTheDocument()
  })

  it('notifies the UI to perform dynamic updates', () => {
    const mockUpdate = jest.fn()
    const {rerender} = render(
      <PlannerApp {...getDefaultValues({isLoading: true})} triggerDynamicUiUpdates={mockUpdate} />
    )
    rerender(
      <PlannerApp {...getDefaultValues({isLoading: false})} triggerDynamicUiUpdates={mockUpdate} />
    )
    expect(mockUpdate).toHaveBeenCalledTimes(1)
  })
})

describe('mapStateToProps', () => {
  it('maps thisWeek from the weeklyDashboard', () => {
    const initProps = getDefaultValues({opportunityCount: 1})
    const state = {
      loading: {
        isLoading: false,
        hasSomeItems: false,
        partialPastDays: [],
        partialFutureDays: [],
        partialWeekDays: [],
      },
      days: [],
      weeklyDashboard: initProps.weeklyDashboard,
      opportunities: {
        items: [{foo: 1}],
      },
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({thisWeek: initProps.thisWeek})
  })
})

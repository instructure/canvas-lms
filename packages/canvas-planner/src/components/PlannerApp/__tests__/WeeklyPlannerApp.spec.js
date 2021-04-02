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
      id: '2'
    },
    days: [],
    timeZone: TZ,
    isWeekly: true,
    changeDashboardView() {},
    isCompletelyEmpty: false,
    weeklyDashboard: {
      weekStart: thisWeekStart,
      weekEnd: thisWeekEnd,
      thisWeek: thisWeekStart,
      weeks: {}
    },
    thisWeek: {
      weekStart: thisWeekStart,
      weekEnd: thisWeekEnd
    },
    loadingOpportunities: false,
    opportunityCount: 0,
    ...overrides
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
  it('renders empty component with no assignments', () => {
    const opts = getDefaultValues()
    const {getByText} = render(<PlannerApp {...opts} />)
    expect(getByText('Nothing Due This Week')).toBeInTheDocument()
  })

  it('displays the whole week if there are any items', () => {
    const opts = getDefaultValues()
    let days = [opts.thisWeek.weekStart.clone().add(1, 'day')]
    days = days.map(d => [d.format('YYYY-MM-DD'), [{dateBucketMoment: d}]])
    const {container, queryAllByText} = render(<PlannerApp {...getDefaultValues({days})} />)
    expect(container.querySelectorAll('.planner-day').length).toEqual(7)
    const d = opts.thisWeek.weekStart.clone()
    for (let i = 0; i < 7; ++i) {
      const dstr = d.format('MMMM D')
      expect(queryAllByText(dstr, {exact: false})[0]).toBeInTheDocument()
      d.add(1, 'day')
    }
  })

  it('shows only the loading component when the isLoading prop is true', () => {
    const {getByText} = render(<PlannerApp {...getDefaultValues()} isLoading />)
    expect(getByText('Loading planner items')).toBeInTheDocument()
  })

  // NOTE: leaving these here as a guide for specs I may need when
  //       we add focus management and fancy scrolling

  // it('notifies the UI to perform dynamic updates', () => {
  //   const mockUpdate = jest.fn()
  //   const wrapper = shallow(
  //     <PlannerApp {...getDefaultValues({isLoading: true})} triggerDynamicUiUpdates={mockUpdate} />,
  //     {disableLifecycleMethods: false}
  //   ) // so componentDidUpdate gets called on setProps
  //   wrapper.setProps({isLoading: false})
  //   expect(mockUpdate).toHaveBeenCalledTimes(1)
  // })

  // describe('focus handling', () => {
  //   const dae = document.activeElement
  //   afterEach(() => {
  //     if (dae) dae.focus() // else ?
  //   })

  //   it('calls fallbackFocus when the load prior focus button disappears', () => {
  //     const focusFallback = jest.fn()
  //     const wrapper = mount(
  //       <PlannerApp
  //         {...getDefaultValues()}
  //         days={[]}
  //         allPastItemsLoaded={false}
  //         focusFallback={focusFallback}
  //       />
  //     )
  //     const button = wrapper.find('ShowOnFocusButton button')
  //     button.getDOMNode().focus()
  //     wrapper.setProps({allPastItemsLoaded: true})
  //     expect(focusFallback).toHaveBeenCalled()
  //   })
  // })
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
        partialWeekDays: []
      },
      days: [],
      weeklyDashboard: initProps.weeklyDashboard,
      opportunities: {
        items: [{foo: 1}]
      }
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({thisWeek: initProps.thisWeek})
  })
})

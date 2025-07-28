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

import {render, waitFor} from '@testing-library/react'
import moment from 'moment-timezone'
import React from 'react'
import {WeeklyPlannerHeader, processFocusTarget} from '../index'

function defaultProps(options) {
  return {
    loadNextWeekItems: () => {},
    loadPastWeekItems: () => {},
    loadThisWeekItems: () => {},
    scrollToToday: () => {},
    toggleMissing: () => {},
    loading: {
      isLoading: false,
      loadingWeek: false,
    },
    todayMoment: moment('2021-03-21T13:00:00Z'),
    visible: true,
    weekStartMoment: moment('2021-03-21'),
    weekEndMoment: moment('2021-03-27'),
    weekLoaded: true,
    wayPastItemDate: '2021-01-01',
    wayFutureItemDate: '2021-12-31',
    toggleMissiong: () => {},
    locale: 'en',
    timeZone: 'America/Denver',
    savePlannerItem: () => {},
    deletePlannerItem: () => {},
    cancelEditingPlannerItem: () => {},
    openEditingPlannerItem: () => {},
    courses: [],
    ...options,
  }
}

afterEach(() => {
  jest.clearAllMocks()
})

describe('WeeklyPlannerHeader', () => {
  it('renders the component', () => {
    const {getByLabelText, getByText} = render(<WeeklyPlannerHeader {...defaultProps()} />)
    expect(getByText('View previous week')).toBeInTheDocument()
    expect(getByText('Jump to Today')).toBeInTheDocument()
    expect(getByText('View next week')).toBeInTheDocument()
    expect(getByLabelText('Weekly schedule navigation')).toBeInTheDocument()
  })

  it('calls loadPastWeekItems when previous week button is clicked', () => {
    const callback = jest.fn()
    const props = defaultProps({loadPastWeekItems: callback})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    getByText('View previous week').closest('button').click()
    expect(callback).toHaveBeenCalled()
  })

  it('calls loadNextWeekItems when next week button is clicked', () => {
    const callback = jest.fn()
    const props = defaultProps({loadNextWeekItems: callback})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    getByText('View next week').closest('button').click()
    expect(callback).toHaveBeenCalled()
  })

  it('calls loadThisWeekItems when Today button is clicked', () => {
    const callback = jest.fn()
    const props = defaultProps({loadThisWeekItems: callback})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    getByText('Today').closest('button').click()
    expect(callback).toHaveBeenCalled()
  })

  it('shows an error message when it should', () => {
    const props = defaultProps({loading: {loadingError: 'whoops'}})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    expect(getByText('Error loading items')).toBeInTheDocument()
  })

  it('disables next week button if there is nothing in the future', () => {
    const callback = jest.fn()
    const props = defaultProps({wayFutureItemDate: '2021-03-25', loadNextWeekItems: callback})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    const button = getByText('View next week').closest('button')
    button.click()
    expect(callback).not.toHaveBeenCalled()
    expect(button.hasAttribute('disabled')).toEqual(true)
  })

  it('disables previous week button if there is nothing in the past', () => {
    const callback = jest.fn()
    const props = defaultProps({wayPastItemDate: '2021-03-25', loadPastWeekItems: callback})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    const button = getByText('View previous week').closest('button')
    button.click()
    expect(callback).not.toHaveBeenCalled()
    expect(button.hasAttribute('disabled')).toEqual(true)
  })

  it('scrolls to today when it becomes visible', async () => {
    const callback = jest.fn()
    const props = defaultProps({visible: false, scrollToToday: callback})
    const {rerender} = render(<WeeklyPlannerHeader {...props} />)
    expect(callback).not.toHaveBeenCalled()

    rerender(<WeeklyPlannerHeader {...props} visible={true} />)
    await waitFor(() => expect(callback).toHaveBeenCalledWith({isWeekly: true}))
  })

  it('scrolls to today when it loads if already visible', async () => {
    const callback = jest.fn()
    const props = defaultProps({scrollToToday: callback, weekLoaded: false})
    const {rerender} = render(<WeeklyPlannerHeader {...props} />)
    expect(callback).not.toHaveBeenCalled()

    rerender(<WeeklyPlannerHeader {...props} weekLoaded={true} />)
    await waitFor(() => expect(callback).toHaveBeenCalledWith({isWeekly: true}))
  })

  it('sends today as a focus target if passed via query param', async () => {
    window.history.pushState({}, null, 'http://localhost?focusTarget=today')
    const callback = jest.fn()
    const props = defaultProps({visible: false, scrollToToday: callback})
    const {rerender} = render(<WeeklyPlannerHeader {...props} />)
    rerender(<WeeklyPlannerHeader {...props} visible={true} />)
    await waitFor(() =>
      expect(callback).toHaveBeenCalledWith({focusTarget: 'today', isWeekly: true}),
    )
  })

  it('sends missing-items as a focus target if passed via query param and expands missing items', async () => {
    window.history.pushState({}, null, 'http://localhost?focusTarget=missing-items')
    const scrollToToday = jest.fn()
    const toggleMissing = jest.fn()
    const props = defaultProps({visible: false, scrollToToday, toggleMissing})
    const {rerender} = render(<WeeklyPlannerHeader {...props} />)
    rerender(<WeeklyPlannerHeader {...props} visible={true} />)
    await waitFor(() => {
      expect(scrollToToday).toHaveBeenCalledWith({focusTarget: 'missing-items', isWeekly: true})
      expect(toggleMissing).toHaveBeenCalledWith({forceExpanded: true})
    })
  })
})

describe('processFocusTarget', () => {
  // fails in jsdom 25
  it.skip('returns the focusTarget query param, removes it from the url, and updates to the new url', () => {
    window.history.pushState({}, null, 'http://localhost?focusTarget=not-a-real-one')
    expect(processFocusTarget()).toBe('not-a-real-one')
    expect(window.history.replaceState).toHaveBeenCalledWith({}, null, 'http://localhost')
  })

  // fails in jsdom 25
  it.skip('keeps other query params intact', () => {
    window.history.pushState(
      {},
      null,
      'http://localhost?first=yes&focusTarget=not-a-real-one&last=no',
    )
    expect(processFocusTarget()).toBe('not-a-real-one')
    expect(window.history.replaceState).toHaveBeenCalledWith(
      {},
      null,
      'http://localhost?first=yes&last=no',
    )
  })

  // fails in jsdom 25
  it.skip('returns undefined if no focusTarget query param was present', () => {
    window.history.pushState({}, null, 'http://localhost?something=else')
    expect(processFocusTarget()).toBe(undefined)
    expect(window.history.replaceState).toHaveBeenCalledWith(
      {},
      null,
      'http://localhost?something=else',
    )
  })

  // fails in jsdom 25
  it.skip('handles urls with no query params', () => {
    window.history.pushState({}, null, 'http://localhost/courses/5#schedule')
    expect(processFocusTarget()).toBe(undefined)
    expect(window.history.replaceState).toHaveBeenCalledWith(
      {},
      null,
      'http://localhost/courses/5#schedule',
    )
  })
})

describe('personal to-dos', () => {
  it('opens the to-do editor if todo updateitem prop is set', () => {
    const todo = {
      updateTodoItem: {
        id: 10,
      },
    }
    const {queryByTestId, rerender} = render(<WeeklyPlannerHeader {...defaultProps()} />)
    expect(queryByTestId('todo-editor-modal')).not.toBeInTheDocument()
    rerender(<WeeklyPlannerHeader {...defaultProps({todo, openEditingPlannerItem: () => {}})} />)
    expect(queryByTestId('todo-editor-modal')).toBeInTheDocument()
  })
})

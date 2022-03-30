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
import {act, screen} from '@testing-library/react'

import {COURSE, PRIMARY_PACE} from '../../../../__tests__/fixtures'
import {renderConnected} from '../../../../__tests__/utils'

import {Settings} from '../settings'

const loadLatestPaceByContext = jest.fn()
const setEditingBlackoutDates = jest.fn()
const showLoadingOverlay = jest.fn()
const toggleExcludeWeekends = jest.fn()
const toggleHardEndDates = jest.fn()
const setEndDate = jest.fn()

const defaultProps = {
  course: COURSE,
  courseId: COURSE.id,
  excludeWeekends: PRIMARY_PACE.exclude_weekends,
  coursePace: PRIMARY_PACE,
  pacePublishing: false,
  loadLatestPaceByContext,
  setEditingBlackoutDates,
  showLoadingOverlay,
  toggleExcludeWeekends,
  toggleHardEndDates,
  setEndDate
}

beforeAll(() => {
  window.ENV.VALID_DATE_RANGE = {
    end_at: {date: COURSE.start_at, date_context: 'course'},
    start_at: {date: COURSE.end_at, date_context: 'course'}
  }
})
afterEach(() => {
  jest.clearAllMocks()
})

describe('Settings', () => {
  it('renders a settings menu with toggles and a button to open the blackout dates modal', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} />)
    const settingsButton = getByRole('button', {name: 'Modify Settings'})
    expect(settingsButton).toBeInTheDocument()

    act(() => settingsButton.click())

    expect(screen.getByRole('checkbox', {name: 'Skip Weekends'})).toBeInTheDocument()
    // Commented out since we're not implementing these features yet
    // expect(screen.getByRole('button', {name: 'View Blackout Dates'})).toBeInTheDocument()
  })

  it('toggles the associated setting when the checkboxes are clicked', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} />)
    const settingsButton = getByRole('button', {name: 'Modify Settings'})
    act(() => settingsButton.click())

    const skipWeekendsToggle = screen.getByRole('checkbox', {name: 'Skip Weekends'})
    expect(skipWeekendsToggle).not.toBeDisabled()
    act(() => skipWeekendsToggle.click())
    expect(toggleExcludeWeekends).toHaveBeenCalled()
  })

  it('disables all settings while publishing', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} pacePublishing />)
    const settingsButton = getByRole('button', {name: 'Modify Settings'})
    act(() => settingsButton.click())

    const skipWeekendsToggle = screen.getByRole('checkbox', {name: 'Skip Weekends'})
    expect(skipWeekendsToggle).toBeDisabled()
  })

  // Skipped since we're not implementing this feature yet
  it.skip('shows and hides the blackout dates modal correctly', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} />)
    const settingsButton = getByRole('button', {name: 'Modify Settings'})
    act(() => settingsButton.click())

    act(() => screen.getByRole('button', {name: 'View Blackout Dates'}).click())
    expect(screen.getByRole('heading', {name: 'Blackout Dates'})).toBeInTheDocument()
    const closeButtons = screen.getAllByRole('button', {name: 'Close'})
    expect(closeButtons.length).toBe(2)

    act(() => closeButtons[0].click())
    expect(screen.queryByRole('heading', {name: 'Blackout Dates'})).not.toBeInTheDocument()
    expect(screen.queryByRole('checkbox', {name: 'Skip Weekends'})).not.toBeInTheDocument()
  })
})

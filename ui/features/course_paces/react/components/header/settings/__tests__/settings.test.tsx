// @ts-nocheck
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

import {BLACKOUT_DATES, COURSE, PRIMARY_PACE, SECTION_PACE} from '../../../../__tests__/fixtures'
import {renderConnected} from '../../../../__tests__/utils'

import {Settings} from '../settings'

const loadLatestPaceByContext = jest.fn()
const showLoadingOverlay = jest.fn()
const toggleExcludeWeekends = jest.fn()
const updateBlackoutDates = jest.fn()

const defaultProps = {
  blackoutDates: BLACKOUT_DATES,
  course: COURSE,
  courseId: COURSE.id,
  excludeWeekends: PRIMARY_PACE.exclude_weekends,
  coursePace: PRIMARY_PACE,
  isSyncing: false,
  loadLatestPaceByContext,
  showLoadingOverlay,
  toggleExcludeWeekends,
  updateBlackoutDates,
}

beforeAll(() => {
  window.ENV.VALID_DATE_RANGE = {
    end_at: {date: COURSE.start_at, date_context: 'course'},
    start_at: {date: COURSE.end_at, date_context: 'course'},
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

    expect(screen.getByRole('menuitemcheckbox', {name: 'Skip Weekends'})).toBeInTheDocument()
    expect(screen.getByRole('menuitem', {name: 'Manage Blackout Dates'})).toBeInTheDocument()
  })

  it('toggles the associated setting when the checkboxes are clicked', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} />)
    const settingsButton = getByRole('button', {name: 'Modify Settings'})
    act(() => settingsButton.click())

    const skipWeekendsToggle = screen.getByRole('menuitemcheckbox', {name: 'Skip Weekends'})
    expect(skipWeekendsToggle).not.toBeDisabled()
    act(() => skipWeekendsToggle.click())
    expect(toggleExcludeWeekends).toHaveBeenCalled()
  })

  it('disables all settings while syncing', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} isSyncing={true} />)
    const settingsButton = getByRole('button', {name: 'Modify Settings'})
    act(() => settingsButton.click())

    const skipWeekendsToggle = screen.getByRole('menuitemcheckbox', {name: 'Skip Weekends'})
    expect(skipWeekendsToggle).toHaveAttribute('aria-disabled', 'true')
    const blackoutDatesBtn = screen.getByRole('menuitem', {name: 'Manage Blackout Dates'})
    expect(blackoutDatesBtn).toHaveAttribute('aria-disabled', 'true')
  })

  it('shows and hides the blackout dates modal correctly', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} />)
    const settingsButton = getByRole('button', {name: 'Modify Settings'})
    act(() => settingsButton.click())

    act(() => screen.getByRole('menuitem', {name: 'Manage Blackout Dates'}).click())
    expect(screen.getByRole('heading', {name: 'Blackout Dates'})).toBeInTheDocument()
    const cancelButton = screen.getByRole('button', {name: 'Cancel'})
    expect(cancelButton).toBeInTheDocument()

    act(() => cancelButton.click())
    expect(screen.queryByRole('heading', {name: 'Blackout Dates'})).not.toBeInTheDocument()
    expect(screen.queryByRole('menuitemcheckbox', {name: 'Skip Weekends'})).not.toBeInTheDocument()
  })

  it('saves blackout dates from modal correctly', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} />)
    const settingsButton = getByRole('button', {name: 'Modify Settings'})
    act(() => settingsButton.click())

    act(() => screen.getByRole('menuitem', {name: 'Manage Blackout Dates'}).click())
    expect(screen.getByRole('heading', {name: 'Blackout Dates'})).toBeInTheDocument()
    const saveButton = screen.getByRole('button', {name: 'Save'})
    expect(saveButton).toBeInTheDocument()

    act(() => saveButton.click())
    expect(screen.queryByRole('heading', {name: 'Blackout Dates'})).not.toBeInTheDocument()
    expect(screen.queryByRole('menuitemcheckbox', {name: 'Skip Weekends'})).not.toBeInTheDocument()
    expect(updateBlackoutDates).toHaveBeenCalledWith(defaultProps.blackoutDates)
  })

  describe('with course paces redesign', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_redesign = true
    })

    it('renders a button with settings text', () => {
      const {getByRole} = renderConnected(<Settings {...defaultProps} />)
      const settingsButton = getByRole('button', {name: 'Settings'})
      expect(settingsButton).toBeInTheDocument()
    })
    it('renders manage blackout dates for course paces', () => {
      const {getByRole} = renderConnected(<Settings {...defaultProps} />)
      const settingsButton = getByRole('button', {name: 'Settings'})
      act(() => settingsButton.click())

      expect(screen.getByRole('menuitem', {name: 'Manage Blackout Dates'})).toBeInTheDocument()
      expect(screen.getByRole('menuitemcheckbox', {name: 'Skip Weekends'})).toBeInTheDocument()
    })
    it('does not render manage blackout dates for non-course paces', () => {
      const {getByRole} = renderConnected(<Settings {...defaultProps} coursePace={SECTION_PACE} />)
      const settingsButton = getByRole('button', {name: 'Settings'})
      act(() => settingsButton.click())

      expect(
        screen.queryByRole('menuitem', {name: 'Manage Blackout Dates'})
      ).not.toBeInTheDocument()
      expect(screen.getByRole('menuitemcheckbox', {name: 'Skip Weekends'})).toBeInTheDocument()
    })
  })
})

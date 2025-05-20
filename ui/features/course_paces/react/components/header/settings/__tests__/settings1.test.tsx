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
import fakeENV from '@canvas/test-utils/fakeENV'

import {
  BLACKOUT_DATES,
  COURSE,
  DEFAULT_STORE_STATE,
  PRIMARY_PACE,
  SECTION_PACE,
} from '../../../../__tests__/fixtures'
import {renderConnected} from '../../../../__tests__/utils'

import {Settings, type ComponentProps} from '../settings'
import type {CoursePace} from 'features/course_paces/react/types'

const toggleExcludeWeekends = jest.fn()
const toggleSelectedDaysToSkip = jest.fn()
const updateBlackoutDates = jest.fn()

const defaultProps: ComponentProps = {
  blackoutDates: BLACKOUT_DATES,
  coursePace: PRIMARY_PACE,
  isSyncing: false,
  toggleExcludeWeekends,
  toggleSelectedDaysToSkip,
  updateBlackoutDates,
  isBlueprintLocked: false,
  responsiveSize: 'large',
}

beforeEach(() => {
  fakeENV.setup({
    VALID_DATE_RANGE: {
      end_at: {date: COURSE.start_at, date_context: 'course'},
      start_at: {date: COURSE.end_at, date_context: 'course'},
    },
    FEATURES: {
      course_paces_skip_selected_days: true,
    },
  })
})

afterEach(() => {
  jest.clearAllMocks()
  fakeENV.teardown()
})

describe('Settings', () => {
  it('renders a settings menu with toggles and a button to open the blackout dates modal', () => {
    renderConnected(<Settings {...defaultProps} />)
    const settingsButton = screen.getByRole('button', {name: 'Settings'})
    act(() => settingsButton.click())

    expect(screen.getByRole('menuitem', {name: 'Skip Selected Days'})).toBeInTheDocument()
    expect(screen.getByRole('menuitem', {name: 'Manage Blackout Dates'})).toBeInTheDocument()
  })

  it('disables all settings while syncing', async () => {
    renderConnected(<Settings {...{...defaultProps, isSyncing: true}} />)
    const settingsButton = screen.getByRole('button', {name: 'Settings'})
    act(() => settingsButton.click())

    // First check the Manage Blackout Dates button in main menu
    const blackoutDatesBtn = screen.getByRole('menuitem', {name: 'Manage Blackout Dates'})
    expect(blackoutDatesBtn).toHaveAttribute('aria-disabled', 'true')

    // Click into Skip Selected Days submenu
    const skipSelectedDays = screen.getByTestId('skip-selected-days')
    act(() => skipSelectedDays.click())

    // Verify weekends option is disabled
    const weekendsOption = screen.getByTestId('skip-weekends-toggle')
    expect(weekendsOption).toHaveAttribute('aria-disabled', 'true')

    // Verify weekday options are disabled
    const mondayOption = screen.getByRole('menuitemcheckbox', {name: 'Mondays'})
    expect(mondayOption).toHaveAttribute('aria-disabled', 'true')
  })

  it('shows and hides the blackout dates modal correctly', () => {
    const {getByRole} = renderConnected(<Settings {...defaultProps} />)
    const settingsButton = getByRole('button', {name: 'Settings'})
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
    const settingsButton = getByRole('button', {name: 'Settings'})
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

  describe('course_paces_skip_selected_days is enabled', () => {
    it('toggles the associated setting when the checkboxes are clicked', () => {
      renderConnected(<Settings {...defaultProps} />)
      const settingsButton = screen.getByRole('button', {name: 'Settings'})
      act(() => settingsButton.click())

      const skipSelectedDaysOption = screen.getByRole('menuitem', {name: 'Skip Selected Days'})
      act(() => skipSelectedDaysOption.click())

      const mondaysOption = screen.getByRole('menuitemcheckbox', {name: 'Mondays'})
      const fridaysOption = screen.getByRole('menuitemcheckbox', {name: 'Fridays'})

      expect(mondaysOption).not.toBeDisabled()
      expect(fridaysOption).not.toBeDisabled()

      act(() => mondaysOption.click())
      act(() => fridaysOption.click())

      expect(toggleSelectedDaysToSkip).toHaveBeenCalledTimes(2)
    })

    it('Skip selected counter pill shows correct information', () => {
      const coursePace = {
        ...DEFAULT_STORE_STATE.coursePace,
        selected_days_to_skip: ['mon', 'tue', 'wed', 'thu', 'fri'],
      } as CoursePace

      const state = {...DEFAULT_STORE_STATE, coursePace}

      renderConnected(<Settings {...defaultProps} />, state)
      const settingsButton = screen.getByRole('button', {name: 'Settings'})
      act(() => settingsButton.click())

      const selectedDaysCounterPill = screen.getByTestId('selected_days_counter')
      expect(selectedDaysCounterPill).toHaveTextContent('5')
    })

    it('disables the last day selector when all other days are skipped', () => {
      const coursePace = {
        ...DEFAULT_STORE_STATE.coursePace,
        selected_days_to_skip: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
      } as CoursePace

      const state = {...DEFAULT_STORE_STATE, coursePace}

      renderConnected(<Settings {...defaultProps} />, state)
      const settingsButton = screen.getByRole('button', {name: 'Settings'})
      act(() => settingsButton.click())

      const skipSelectedDaysOption = screen.getByRole('menuitem', {name: /Skip Selected Days/i})
      act(() => skipSelectedDaysOption.click())

      const sundaysOption = screen.getByRole('menuitemcheckbox', {name: 'Sundays'})

      expect(sundaysOption.getAttribute('aria-disabled')).toBe('true')
    })

    it('disables weekend selector when all week days are skipped', () => {
      const coursePace = {
        ...DEFAULT_STORE_STATE.coursePace,
        selected_days_to_skip: ['mon', 'tue', 'wed', 'thu', 'fri'],
      } as CoursePace

      const state = {...DEFAULT_STORE_STATE, coursePace}

      renderConnected(<Settings {...defaultProps} />, state)
      const settingsButton = screen.getByRole('button', {name: 'Settings'})
      act(() => settingsButton.click())

      const skipSelectedDaysOption = screen.getByRole('menuitem', {name: /Skip Selected Days/i})
      act(() => skipSelectedDaysOption.click())

      expect(
        screen.getByRole('menuitemcheckbox', {name: 'Weekends'}).getAttribute('aria-disabled'),
      ).toBe('true')
    })
  })

  describe('course_paces_skip_selected_days is disabled', () => {
    beforeEach(() => {
      fakeENV.setup({
        VALID_DATE_RANGE: {
          end_at: {date: COURSE.start_at, date_context: 'course'},
          start_at: {date: COURSE.end_at, date_context: 'course'},
        },
        FEATURES: {
          course_paces_skip_selected_days: false,
        },
      })
    })
    it('toggles the associated setting when the checkboxes are clicked', () => {
      renderConnected(<Settings {...defaultProps} />)
      const settingsButton = screen.getByRole('button', {name: 'Settings'})
      act(() => settingsButton.click())

      const skipWeekendsToggle = screen.getByRole('menuitemcheckbox', {name: 'Skip Weekends'})
      expect(skipWeekendsToggle).not.toBeDisabled()
      act(() => skipWeekendsToggle.click())
      expect(toggleExcludeWeekends).toHaveBeenCalled()
    })
  })
})

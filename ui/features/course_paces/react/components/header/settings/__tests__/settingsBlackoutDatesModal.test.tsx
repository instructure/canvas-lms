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

import {BLACKOUT_DATES, COURSE, PRIMARY_PACE} from '../../../../__tests__/fixtures'
import {renderConnected} from '../../../../__tests__/utils'

import {Settings, type ComponentProps} from '../settings'

const toggleExcludeWeekends = vi.fn()
const toggleSelectedDaysToSkip = vi.fn()
const updateBlackoutDates = vi.fn()

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
  vi.clearAllMocks()
  fakeENV.teardown()
})

describe('Settings Blackout Dates Modal', () => {
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
})

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

import {BLACKOUT_DATES, COURSE, PRIMARY_PACE, SECTION_PACE} from '../../../../__tests__/fixtures'
import {renderConnected} from '../../../../__tests__/utils'

import {Settings, type ComponentProps} from '../settings'

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
  describe('with course paces redesign', () => {
    beforeEach(() => {
      fakeENV.setup({
        VALID_DATE_RANGE: {
          end_at: {date: COURSE.start_at, date_context: 'course'},
          start_at: {date: COURSE.end_at, date_context: 'course'},
        },
      })
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
        screen.queryByRole('menuitem', {name: 'Manage Blackout Dates'}),
      ).not.toBeInTheDocument()
      expect(screen.getByRole('menuitemcheckbox', {name: 'Skip Weekends'})).toBeInTheDocument()
    })
  })

  describe('course_pace_weighted_assignments is enabled', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          course_pace_weighted_assignments: true,
        },
      })
    })

    it('renders set weighted assignment duration menu option', () => {
      renderConnected(<Settings {...defaultProps} />)
      const settingsButton = screen.getByRole('button', {name: 'Settings'})
      act(() => settingsButton.click())

      const weightedAssignmentsOption = screen.getByTestId('weighted-assignment-duration-option')
      expect(weightedAssignmentsOption).toBeInTheDocument()
    })
  })

  it('set weighted assignment duration menu option is not displayed', () => {
    renderConnected(<Settings {...defaultProps} />)
    const settingsButton = screen.getByRole('button', {name: 'Settings'})
    act(() => settingsButton.click())

    expect(screen.queryByTestId('weighted-assignment-duration-option')).not.toBeInTheDocument()
  })
})

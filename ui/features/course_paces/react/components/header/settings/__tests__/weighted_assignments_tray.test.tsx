/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import fakeENV from '@canvas/test-utils/fakeENV'
import { renderConnected } from '../../../../__tests__/utils'
import { screen, fireEvent } from '@testing-library/react'
import { actions as uiActions } from '../../../../actions/ui'
import WeightedAssignmentsTray from './../WeightedAssignmentsTray'
import { StoreState } from '../../../../types'
import { BLACKOUT_DATES, DEFAULT_STORE_STATE, PRIMARY_PACE } from '../../../../__tests__/fixtures'

jest.mock('../../../../actions/ui', () => ({
  ...jest.requireActual('../../../../actions/ui'),
  actions: {
    hideWeightedAssignmentsTray: jest.fn().mockReturnValue({ type: 'UI/HIDE_WEIGHTING_ASSIGNMENTS_MODAL', payload: {} }),
  },
}))

const defaultStoreState: StoreState = {
  ...DEFAULT_STORE_STATE,
  original: {
    coursePace: {
      ...PRIMARY_PACE,
      workflow_state: 'unpublished'
    },
    blackoutDates: BLACKOUT_DATES
  },
  ui: {
    ...DEFAULT_STORE_STATE.ui,
    showWeightedAssignmentsTray: true,
  },
}

type durationItemType = "assignment" | "quiz" | "discussion" | "page"

beforeEach(() => {
  fakeENV.setup({
    FEATURES: {
      course_pace_weighted_assignments: true,
    },
  })
})

describe('WeightedAssignmentsTray', () => {
  const runTests = (item: durationItemType) => {
    it(`render the right value for ${item}`, () => {
      renderConnected(<WeightedAssignmentsTray />, defaultStoreState)

      const currentValue = PRIMARY_PACE.assignments_weighting[item] || 0

      expect(screen.getByTestId(`duration-${item}`).querySelector('input')).toHaveValue(currentValue.toString())
    })

    it('increments the duration values', () => {
      renderConnected(<WeightedAssignmentsTray />, defaultStoreState)

      const incrementButton = screen.getByTestId(`duration-${item}`)
        .querySelector('svg[name="IconArrowOpenUp"]')
        ?.closest('button') as HTMLButtonElement
      fireEvent.mouseDown(incrementButton)

      const currentValue = PRIMARY_PACE.assignments_weighting[item] || 0
      expect(screen.getByTestId(`duration-${item}`).querySelector('input')).toHaveValue((currentValue + 1).toString())
    })

    it('decrements the duration values', () => {
      renderConnected(<WeightedAssignmentsTray />, defaultStoreState)

      const incrementButton = screen.getByTestId(`duration-${item}`)
        .querySelector('svg[name="IconArrowOpenDown"]')
        ?.closest('button') as HTMLButtonElement
      fireEvent.mouseDown(incrementButton)

      const currentValue = PRIMARY_PACE.assignments_weighting[item] || 0

      expect(screen.getByTestId(`duration-${item}`).querySelector('input')).toHaveValue((currentValue - 1).toString())
    })
  }

  describe('Duration items inputs', () => {
    runTests("assignment")
    runTests("quiz")
    runTests("discussion")
    runTests("page")
  })

  describe('weighted assignments validations', () => {
    it('should close the tray when the close button is clicked', () => {
      const { getByText } = renderConnected(<WeightedAssignmentsTray />, defaultStoreState)
      const cancelButton = getByText('Cancel').closest('button') as HTMLButtonElement
      fireEvent.click(cancelButton)

      expect(uiActions.hideWeightedAssignmentsTray).toHaveBeenCalled()
    })

    it('Alert message is shown when validation error', () => {
      const storeState: StoreState = {
        ...defaultStoreState,
        coursePace: {
          ...PRIMARY_PACE,
          time_to_complete_calendar_days: 2,
          assignments_weighting: {
            assignment: 2,
            quiz: 2,
            discussion: 2,
            page: 2,
          },
        },
      }
      const { getByTestId } = renderConnected(<WeightedAssignmentsTray />, storeState)
      const incrementButton = getByTestId('duration-assignment')
        .querySelector('svg[name="IconArrowOpenUp"]')
        ?.closest('button') as HTMLButtonElement
      fireEvent.mouseDown(incrementButton)

      const validationMessage = getByTestId('validation-message')
      expect(validationMessage).toBeInTheDocument()
    })

    it('Alert message is focused when validation error and apply button clicked', () => {
      const storeState: StoreState = {
        ...defaultStoreState,
        coursePace: {
          ...PRIMARY_PACE,
          workflow_state: 'unpublished',
          assignments_weighting: {
            assignment: 8,
            quiz: 2,
            discussion: 8,
            page: 0,
          },
          time_to_complete_calendar_days: 2,
          start_date: '2021-12-15',
          end_date: '2021-12-17',
        },
      }
      const { getByTestId } = renderConnected(<WeightedAssignmentsTray />, storeState)
      const incrementButton = getByTestId('duration-assignment')
        .querySelector('svg[name="IconArrowOpenUp"]')
        ?.closest('button') as HTMLButtonElement
      fireEvent.mouseDown(incrementButton)

      const applyButton = getByTestId('weighted-assignments-apply-button').closest('button') as HTMLButtonElement
      fireEvent.click(applyButton)

      const validationMessage = screen.getByTestId('validation-message')
      expect(validationMessage).toHaveFocus()
    })
  })
})

/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import DateAdjustments from '../date_adjustments'
import type {DateAdjustmentConfig, DateShifts} from '../types'
import userEvent from '@testing-library/user-event'

const dateAdjustments: DateAdjustmentConfig = {
  adjust_dates: {
    enabled: false,
    operation: 'shift_dates',
  },
  date_shift_options: {
    substitutions: {},
    old_start_date: false,
    new_start_date: false,
    old_end_date: false,
    new_end_date: false,
    day_substitutions: [],
  },
}

const dateAdjustmentsWithSub: DateAdjustmentConfig = {
  adjust_dates: {
    enabled: false,
    operation: 'shift_dates',
  },
  date_shift_options: {
    substitutions: {},
    old_start_date: false,
    new_start_date: false,
    old_end_date: false,
    new_end_date: false,
    day_substitutions: [{from: 0, id: 1, to: 0}],
  },
}

const setDateAdjustments: (cfg: DateAdjustmentConfig) => void = jest.fn()

describe('DateAdjustment', () => {
  afterEach(() => jest.clearAllMocks())

  it('Fill in with empty values the start and end date fileds', () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustments}
        setDateAdjustments={setDateAdjustments}
      />
    )
    expect(screen.getByLabelText('Select new beginning date').closest('input')?.value).toBe('')
    expect(screen.getByLabelText('Select new end date').closest('input')?.value).toBe('')
  })

  it('Renders proper date operation radio buttons', () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustments}
        setDateAdjustments={setDateAdjustments}
      />
    )
    expect(screen.getByRole('radio', {name: 'Shift dates', hidden: false})).toBeInTheDocument()
    expect(screen.getByRole('radio', {name: 'Remove dates', hidden: false})).toBeInTheDocument()
  })

  describe('Date fill in on initial data', () => {
    const dateSting = '2024-08-08T08:00:00+00:00'
    const expectedDate = 'Aug 8 at 8am'
    const getComponent = (dateShiftOptionVariant: Partial<DateShifts>) => {
      return (
        <DateAdjustments
          dateAdjustmentConfig={{
            ...dateAdjustments,
            date_shift_options: {
              ...dateAdjustments.date_shift_options,
              ...dateShiftOptionVariant,
            },
          }}
          setDateAdjustments={setDateAdjustments}
        />
      )
    }

    const expectDateField = (label: string, value: string) => {
      expect(screen.getByLabelText(label).closest('input')?.value).toBe(value)
    }

    it('Fill in original beginning date with old_start_date', () => {
      render(getComponent({old_start_date: dateSting}))
      expectDateField('Select original beginning date', expectedDate)
    })

    it('Fill in original end date with old_end_date', () => {
      render(getComponent({old_end_date: dateSting}))
      expectDateField('Select original end date', expectedDate)
    })

    it('Fill in new beginning date with new_start_date', () => {
      render(getComponent({new_start_date: dateSting}))
      expectDateField('Select new beginning date', expectedDate)
    })

    it('Fill in new end date with new_end_date', () => {
      render(getComponent({new_end_date: dateSting}))
      expectDateField('Select new end date', expectedDate)
    })
  })

  it('Renders/hides date shifting UI when appropriate', async () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustments}
        setDateAdjustments={setDateAdjustments}
      />
    )
    await userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    expect(screen.getByLabelText('Select original beginning date')).toBeInTheDocument()
    expect(screen.getByLabelText('Select new beginning date')).toBeInTheDocument()
    expect(screen.getByLabelText('Select original end date')).toBeInTheDocument()
    expect(screen.getByLabelText('Select new end date')).toBeInTheDocument()
    await userEvent.click(screen.getByRole('radio', {name: 'Remove dates', hidden: false}))
    expect(screen.queryByLabelText('Select original beginning date')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Select new beginning date')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Select original end date')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Select new end date')).not.toBeInTheDocument()
  })

  it('Allows adding multiple weekday substitutions', async () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustments}
        setDateAdjustments={setDateAdjustments}
      />
    )
    await userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    await userEvent.click(screen.getByRole('button', {name: 'Add substitution', hidden: false}))
    expect(setDateAdjustments).toHaveBeenCalledWith(dateAdjustmentsWithSub)
  })

  it('Allows removing multiple weekday substitutions', async () => {
    render(
      <DateAdjustments
        dateAdjustmentConfig={dateAdjustmentsWithSub}
        setDateAdjustments={setDateAdjustments}
      />
    )
    await userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    const remove_sub_button = screen.getByRole('button', {
      name: "Remove 'Sunday' to 'Sunday' from substitutes",
      hidden: false,
    })
    expect(remove_sub_button).toBeInTheDocument()
    await userEvent.click(remove_sub_button)
    expect(setDateAdjustments).toHaveBeenCalledWith(dateAdjustments)
  })
})

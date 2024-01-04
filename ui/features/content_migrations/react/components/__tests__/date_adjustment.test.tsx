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
import type {DateAdjustmentConfig} from '../types'
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

  it('Renders proper date operation radio buttons', () => {
    render(
      <DateAdjustments dateAdjustments={dateAdjustments} setDateAdjustments={setDateAdjustments} />
    )
    expect(screen.getByRole('radio', {name: 'Shift dates', hidden: false})).toBeInTheDocument()
    expect(screen.getByRole('radio', {name: 'Remove dates', hidden: false})).toBeInTheDocument()
  })

  it('Renders/hides date shifting UI when appropriate', () => {
    render(
      <DateAdjustments dateAdjustments={dateAdjustments} setDateAdjustments={setDateAdjustments} />
    )
    userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    expect(
      screen.getByRole('combobox', {name: 'Select original beginning date', hidden: false})
    ).toBeInTheDocument()
    expect(
      screen.getByRole('combobox', {name: 'Select new beginning date', hidden: false})
    ).toBeInTheDocument()
    expect(
      screen.getByRole('combobox', {name: 'Select original end date', hidden: false})
    ).toBeInTheDocument()
    expect(
      screen.getByRole('combobox', {name: 'Select new end date', hidden: false})
    ).toBeInTheDocument()
    userEvent.click(screen.getByRole('radio', {name: 'Remove dates', hidden: false}))
    expect(
      screen.queryByRole('combobox', {name: 'Select original beginning date', hidden: false})
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole('combobox', {name: 'Select new beginning date', hidden: false})
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole('combobox', {name: 'Select original end date', hidden: false})
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole('combobox', {name: 'Select new end date', hidden: false})
    ).not.toBeInTheDocument()
  })

  it('Allows adding multiple weekday substitutions', () => {
    render(
      <DateAdjustments dateAdjustments={dateAdjustments} setDateAdjustments={setDateAdjustments} />
    )
    userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    userEvent.click(screen.getByRole('button', {name: 'Add substitution', hidden: false}))
    expect(setDateAdjustments).toHaveBeenCalledWith(dateAdjustmentsWithSub)
  })

  it('Allows removing multiple weekday substitutions', () => {
    render(
      <DateAdjustments
        dateAdjustments={dateAdjustmentsWithSub}
        setDateAdjustments={setDateAdjustments}
      />
    )
    userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    const remove_sub_button = screen.getByRole('button', {
      name: "Remove 'Sunday' to 'Sunday' from substitutes",
      hidden: false,
    })
    expect(remove_sub_button).toBeInTheDocument()
    userEvent.click(remove_sub_button)
    expect(setDateAdjustments).toHaveBeenCalledWith(dateAdjustments)
  })
})

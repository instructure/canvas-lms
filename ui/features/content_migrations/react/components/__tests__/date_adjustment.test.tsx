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

  it('Renders/hides date shifting UI when appropriate', async () => {
    render(
      <DateAdjustments dateAdjustments={dateAdjustments} setDateAdjustments={setDateAdjustments} />
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
      <DateAdjustments dateAdjustments={dateAdjustments} setDateAdjustments={setDateAdjustments} />
    )
    await userEvent.click(screen.getByRole('radio', {name: 'Shift dates', hidden: false}))
    await userEvent.click(screen.getByRole('button', {name: 'Add substitution', hidden: false}))
    expect(setDateAdjustments).toHaveBeenCalledWith(dateAdjustmentsWithSub)
  })

  it('Allows removing multiple weekday substitutions', async () => {
    render(
      <DateAdjustments
        dateAdjustments={dateAdjustmentsWithSub}
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

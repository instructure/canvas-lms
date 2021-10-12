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
import {fireEvent, render} from '@testing-library/react'

import {BLACKOUT_DATES, PRIMARY_PLAN, STUDENT_PLAN} from '../../../../__tests__/fixtures'

import {StartDateSelector} from '../start_date_selector'

const setStartDate = jest.fn()

const defaultProps = {
  blackoutDates: BLACKOUT_DATES,
  disabledDaysOfWeek: [],
  setStartDate,
  pacePlan: PRIMARY_PLAN
}

describe('StartDateSelector', () => {
  it('renders an editable "Projected Start Date" selector for primary pace plans', () => {
    const {getByRole} = render(<StartDateSelector {...defaultProps} />)
    const startDateInput = getByRole('combobox', {name: 'Projected Start Date'}) as HTMLInputElement
    expect(startDateInput).toBeInTheDocument()
    expect(startDateInput.value).toBe('September 1, 2021')

    fireEvent.change(startDateInput, {target: {value: 'September 3, 2021'}})
    fireEvent.blur(startDateInput)
    expect(setStartDate).toHaveBeenCalledWith('2021-09-03')
  })

  it('renders read-only "Start Date" text for student pace plans', () => {
    const {getByText, queryByRole} = render(
      <StartDateSelector {...defaultProps} pacePlan={STUDENT_PLAN} />
    )
    expect(getByText('Start Date')).toBeInTheDocument()
    expect(getByText('October 1, 2021')).toBeInTheDocument()
    expect(queryByRole('combobox')).not.toBeInTheDocument()
  })
})

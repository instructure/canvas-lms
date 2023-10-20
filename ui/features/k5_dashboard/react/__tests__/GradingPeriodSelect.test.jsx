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
 *
 */

import React from 'react'
import {act, render} from '@testing-library/react'
import GradingPeriodSelect from '../GradingPeriodSelect'
import {GRADING_PERIODS} from '@canvas/k5/react/__tests__/fixtures'

const defaultProps = {
  gradingPeriods: GRADING_PERIODS,
  handleSelectGradingPeriod: () => {},
  selectedGradingPeriodId: '',
}

describe('GradingPeriodSelect', () => {
  it('renders a select with the title "Select Grading Period"', () => {
    const {getByRole} = render(<GradingPeriodSelect {...defaultProps} />)
    const select = getByRole('combobox', {name: 'Select Grading Period'})

    expect(select).toBeInTheDocument()
  })

  it('has "Current Grading Period" selected by default', () => {
    const {getByRole} = render(<GradingPeriodSelect {...defaultProps} />)
    const select = getByRole('combobox', {name: 'Select Grading Period'})

    expect(select.value).toBe('Current Grading Period')
  })

  it('Renders an option for every active grading period plus current grading periods', () => {
    const {getByRole, getByText, queryByText} = render(<GradingPeriodSelect {...defaultProps} />)
    act(() => getByRole('combobox', {name: 'Select Grading Period'}).click())

    expect(getByText('Current Grading Period')).toBeInTheDocument()
    expect(getByText('Spring 2020')).toBeInTheDocument()
    expect(getByText('Fall 2020')).toBeInTheDocument()
    expect(getByText('All Grading Periods')).toBeInTheDocument()
    expect(queryByText('Spring 2019')).not.toBeInTheDocument()
  })

  it('Calls the provided callback with the selected grading period id', () => {
    const handleSelectGradingPeriod = jest.fn()
    const {getByRole, getByText} = render(
      <GradingPeriodSelect
        {...defaultProps}
        handleSelectGradingPeriod={handleSelectGradingPeriod}
      />
    )
    act(() => getByRole('combobox', {name: 'Select Grading Period'}).click())
    act(() => getByText('Fall 2020').click())

    expect(handleSelectGradingPeriod).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({value: '2'})
    )
  })
})

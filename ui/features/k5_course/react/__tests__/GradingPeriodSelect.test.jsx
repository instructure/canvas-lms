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
import {render, act} from '@testing-library/react'
import GradingPeriodSelect from '../GradingPeriodSelect'
import {GRADING_PERIODS} from '@canvas/k5/react/__tests__/fixtures'

describe('GradingPeriodSelect', () => {
  const getProps = (overrides = {}) => ({
    loadingGradingPeriods: false,
    gradingPeriods: GRADING_PERIODS,
    onGradingPeriodSelected: jest.fn(),
    currentGradingPeriodId: '2',
    courseName: 'History',
    ...overrides,
  })

  it('renders a select with provided active grading periods and all periods as options', () => {
    const {getByText, queryByText} = render(
      <GradingPeriodSelect {...getProps({currentGradingPeriodId: undefined})} />
    )
    act(() => getByText('Select Grading Period').click())
    expect(getByText('Spring 2020')).toBeInTheDocument()
    expect(getByText('Fall 2020')).toBeInTheDocument()
    expect(getByText('All Grading Periods')).toBeInTheDocument()
    expect(queryByText('Fall 2019')).not.toBeInTheDocument()
  })

  it('marks the current grading period option', () => {
    const {getByText} = render(<GradingPeriodSelect {...getProps()} />)
    act(() => getByText('Select Grading Period').click())
    expect(getByText('Fall 2020 (Current)')).toBeInTheDocument()
  })

  it('calls setSelectedGradingPeriodId with id of selected grading period', () => {
    const onGradingPeriodSelected = jest.fn()
    const {getByText} = render(<GradingPeriodSelect {...getProps({onGradingPeriodSelected})} />)

    act(() => getByText('Select Grading Period').click())
    act(() => getByText('Spring 2020').click())
    expect(onGradingPeriodSelected).toHaveBeenCalledWith('1')

    act(() => getByText('Select Grading Period').click())
    act(() => getByText('All Grading Periods').click())
    expect(onGradingPeriodSelected).toHaveBeenCalledWith(null)
  })

  it('shows a loading skeleton if loadingGradingPeriods is set', () => {
    const {getByText} = render(<GradingPeriodSelect {...getProps({loadingGradingPeriods: true})} />)
    expect(getByText('Loading grading periods for History')).toBeInTheDocument()
  })
})

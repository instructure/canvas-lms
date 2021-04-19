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

const defaultProps = {
  gradingPeriods: [
    {
      id: '1',
      title: 'Spring 2020',
      start_date: '2020-01-01T07:00:00Z',
      end_date: '2020-07-01T06:59:59Z',
      workflow_state: 'active'
    },
    {
      id: '2',
      title: 'Fall 2020',
      start_date: '2020-07-01T07:00:00Z',
      end_date: '2021-01-01T06:59:59Z',
      workflow_state: 'active'
    },
    {
      id: '3',
      title: 'Fall 2019',
      start_date: '2019-07-01T07:00:00Z',
      end_date: '2020-01-01T06:59:59Z',
      workflow_state: 'deleted'
    }
  ],
  handleSelectGradingPeriod: () => {},
  selectedGradingPeriodId: ''
}

describe('GradingPeriodSelect', () => {
  it('renders a select with the title "Select Grading Period"', () => {
    const {getByRole} = render(<GradingPeriodSelect {...defaultProps} />)
    const select = getByRole('button', {name: 'Select Grading Period'})

    expect(select).toBeInTheDocument()
  })

  it('has "Current Grading Period" selected by default', () => {
    const {getByRole} = render(<GradingPeriodSelect {...defaultProps} />)
    const select = getByRole('button', {name: 'Select Grading Period'})

    expect(select.value).toBe('Current Grading Period')
  })

  it('Renders an option for every active grading period plus current grading periods', () => {
    const {getByRole, getByText, queryByText} = render(<GradingPeriodSelect {...defaultProps} />)
    act(() => getByRole('button', {name: 'Select Grading Period'}).click())

    expect(getByText('Current Grading Period')).toBeInTheDocument()
    expect(getByText('Spring 2020')).toBeInTheDocument()
    expect(getByText('Fall 2020')).toBeInTheDocument()
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
    act(() => getByRole('button', {name: 'Select Grading Period'}).click())
    act(() => getByText('Fall 2020').click())

    expect(handleSelectGradingPeriod).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({value: '2'})
    )
  })
})

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
import {render} from '@testing-library/react'

import {BLACKOUT_DATES} from '../../../../__tests__/fixtures'

import {EndDateSelector} from '../end_date_selector'

const setEndDate = jest.fn()

const defaultProps = {
  blackoutDates: BLACKOUT_DATES,
  disabledDaysOfWeek: [],
  pacePlanType: 'Course' as const,
  projectedEndDate: '2021-11-03',
  setEndDate,
  startDate: '2021-10-01'
}

describe('EndDateSelector', () => {
  it('renders read-only "Projected End Date" text for primary pace plans', () => {
    const {getByText, queryByRole} = render(<EndDateSelector {...defaultProps} />)
    expect(getByText('Projected End Date')).toBeInTheDocument()
    expect(getByText('November 3, 2021')).toBeInTheDocument()
    expect(queryByRole('combobox')).not.toBeInTheDocument()
  })

  it('renders read-only "End Date" text for student pace plans', () => {
    const {getByText, queryByRole} = render(
      <EndDateSelector {...defaultProps} pacePlanType="Enrollment" projectedEndDate="2021-10-15" />
    )
    expect(getByText('End Date')).toBeInTheDocument()
    expect(getByText('October 15, 2021')).toBeInTheDocument()
    expect(queryByRole('combobox')).not.toBeInTheDocument()
  })
})

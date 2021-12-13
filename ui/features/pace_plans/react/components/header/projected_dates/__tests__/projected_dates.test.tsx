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
import {renderConnected} from '../../../../__tests__/utils'

import {ProjectedDates} from '../projected_dates'

const defaultProps = {
  assignments: 5,
  planWeeks: 8,
  showProjections: true
}

describe('ProjectedDates', () => {
  it('shows nothing when projections are hidden', () => {
    const {queryByRole} = renderConnected(
      <ProjectedDates {...defaultProps} showProjections={false} />
    )
    expect(queryByRole('combobox')).not.toBeInTheDocument()
  })

  it('shows projected start and end date selectors when projections are shown', () => {
    const {getByRole, getByText} = renderConnected(<ProjectedDates {...defaultProps} />)
    const startDateInput = getByRole('combobox', {name: 'Projected Start Date'}) as HTMLInputElement
    expect(startDateInput).toBeInTheDocument()
    expect(startDateInput.value).toBe('September 1, 2021')
    expect(getByText('Projected End Date')).toBeInTheDocument()
    expect(getByText('September 15, 2021')).toBeInTheDocument()
  })

  it('shows the number of assignments and weeks in the plan when projections are shown', () => {
    const {getByText} = renderConnected(<ProjectedDates {...defaultProps} />)
    expect(getByText('5 assignments')).toBeInTheDocument()
    expect(getByText('8 weeks')).toBeInTheDocument()
  })
})

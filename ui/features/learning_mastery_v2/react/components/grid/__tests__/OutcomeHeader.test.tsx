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
import {render, fireEvent} from '@testing-library/react'
import {pick} from 'es-toolkit/compat'
import {defaultRatings, defaultMasteryPoints} from '@canvas/outcomes/react/hooks/useRatings'
import {OutcomeHeader, OutcomeHeaderProps} from '../OutcomeHeader'
import {Outcome} from '../../../types/rollup'
import {SortOrder, SortBy} from '../../../utils/constants'

describe('OutcomeHeader', () => {
  const outcome: Outcome = {
    id: '1',
    title: 'outcome 1',
    description: 'Outcome description',
    display_name: 'Friendly outcome name',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    points_possible: 5,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery']),
    ),
  }

  const defaultProps = (): OutcomeHeaderProps => {
    return {
      outcome,
      sorting: {
        sortOrder: SortOrder.ASC,
        setSortOrder: jest.fn(),
        sortBy: SortBy.SortableName,
        setSortBy: jest.fn(),
        sortOutcomeId: null,
        setSortOutcomeId: jest.fn(),
      },
    }
  }

  it('renders the outcome title', () => {
    const {getByText} = render(<OutcomeHeader {...defaultProps()} />)
    expect(getByText('outcome 1')).toBeInTheDocument()
  })

  it('renders a menu with various sorting and display options', () => {
    const {getByText} = render(<OutcomeHeader {...defaultProps()} />)
    fireEvent.click(getByText('Sort Outcome Column'))
    expect(getByText('Sort')).toBeInTheDocument()
    expect(getByText('Ascending scores')).toBeInTheDocument()
    expect(getByText('Descending scores')).toBeInTheDocument()
    expect(getByText('Display')).toBeInTheDocument()
    expect(getByText('Hide Contributing Scores')).toBeInTheDocument()
    expect(getByText('Outcome Info')).toBeInTheDocument()
    expect(getByText('Show Outcome Distribution')).toBeInTheDocument()
  })

  it('renders the outcome description modal when option is selected', () => {
    const {getByText, getByTestId} = render(<OutcomeHeader {...defaultProps()} />)
    fireEvent.click(getByText('Sort Outcome Column'))
    fireEvent.click(getByText('Outcome Info'))
    expect(getByTestId('outcome-description-modal')).toBeInTheDocument()
  })
})

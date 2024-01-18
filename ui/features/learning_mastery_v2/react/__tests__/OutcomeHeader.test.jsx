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
import {pick} from 'lodash'
import {defaultRatings, defaultMasteryPoints} from '@canvas/outcomes/react/hooks/useRatings'
import OutcomeHeader from '../OutcomeHeader'

describe('OutcomeHeader', () => {
  const outcome = {
    id: '1',
    title: 'outcome 1',
    description: 'Outcome description',
    display_name: 'Friendly outcome name',
    context_type: 'Account',
    context_id: '1',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    mastery_points: defaultMasteryPoints,
    ratings: defaultRatings.map(rating =>
      pick(rating, ['description', 'points', 'color', 'mastery'])
    ),
  }

  const defaultProps = () => {
    return {
      outcome: outcome,
    }
  }

  it('renders the outcome title', () => {
    const {getByText} = render(<OutcomeHeader {...defaultProps()} />)
    expect(getByText('outcome 1')).toBeInTheDocument()
  })

  it('renders a menu with various sorting options', () => {
    const {getByText} = render(<OutcomeHeader {...defaultProps()} />)
    fireEvent.click(getByText('Sort Outcome Column'))
    expect(getByText('Sort By')).toBeInTheDocument()
    expect(getByText('Default').closest('[role=menuitemradio]')).toBeChecked()
    expect(getByText('Ascending')).toBeInTheDocument()
    expect(getByText('Descending')).toBeInTheDocument()
    expect(getByText('Show Contributing Scores')).toBeInTheDocument()
    expect(getByText('Outcome Description')).toBeInTheDocument()
  })

  it('renders the outcome description modal when option is selected', () => {
    const {getByText, getByTestId} = render(<OutcomeHeader {...defaultProps()} />)
    fireEvent.click(getByText('Sort Outcome Column'))
    fireEvent.click(getByText('Outcome Description'))
    expect(getByTestId('outcome-description-modal')).toBeInTheDocument()
  })
})

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
import {render, screen, fireEvent} from '@testing-library/react'
import {pick} from 'es-toolkit/compat'
import {defaultRatings, defaultMasteryPoints} from '@canvas/outcomes/react/hooks/useRatings'
import {OutcomeHeader, OutcomeHeaderProps} from '../OutcomeHeader'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {SortOrder, SortBy} from '@canvas/outcomes/react/utils/constants'
import {ContributingScoresForOutcome} from '@canvas/outcomes/react/hooks/useContributingScores'

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

  const mockContributingScoresForOutcome: ContributingScoresForOutcome = {
    isVisible: () => false,
    toggleVisibility: vi.fn(),
    data: undefined,
    alignments: undefined,
    scoresForUser: vi.fn(() => []),
    isLoading: false,
    error: undefined,
  }

  const defaultProps = (): OutcomeHeaderProps => {
    return {
      outcome,
      sorting: {
        sortOrder: SortOrder.ASC,
        setSortOrder: vi.fn(),
        sortBy: SortBy.SortableName,
        setSortBy: vi.fn(),
        sortOutcomeId: null,
        setSortOutcomeId: vi.fn(),
        sortAlignmentId: null,
        setSortAlignmentId: vi.fn(),
      },
      contributingScoresForOutcome: mockContributingScoresForOutcome,
      scores: [3, 4, 5, 2, 4],
    }
  }

  it('renders the outcome title', () => {
    render(<OutcomeHeader {...defaultProps()} />)
    expect(screen.getAllByText('outcome 1')[0]).toBeInTheDocument()
  })

  it('renders a menu with various sorting and display options', () => {
    render(<OutcomeHeader {...defaultProps()} />)
    fireEvent.click(screen.getByText('outcome 1 options'))
    expect(screen.getByText('Sort')).toBeInTheDocument()
    expect(screen.getByText('Ascending scores')).toBeInTheDocument()
    expect(screen.getByText('Descending scores')).toBeInTheDocument()
    expect(screen.getByText('Display')).toBeInTheDocument()
    expect(screen.getByText('Show Contributing Scores')).toBeInTheDocument()
    expect(screen.getByText('Outcome Info')).toBeInTheDocument()
    expect(screen.getByText('Show Outcome Distribution')).toBeInTheDocument()
  })

  it('renders the outcome description modal when option is selected', () => {
    render(<OutcomeHeader {...defaultProps()} />)
    fireEvent.click(screen.getByText('outcome 1 options'))
    fireEvent.click(screen.getByText('Outcome Info'))
    expect(screen.getByTestId('outcome-description-modal')).toBeInTheDocument()
  })

  it('renders the outcome distribution popover when option is selected', () => {
    render(<OutcomeHeader {...defaultProps()} />)
    fireEvent.click(screen.getByText('outcome 1 options'))
    fireEvent.click(screen.getByText('Show Outcome Distribution'))
    expect(screen.getByTestId('outcome-distribution-popover')).toBeInTheDocument()
  })
})

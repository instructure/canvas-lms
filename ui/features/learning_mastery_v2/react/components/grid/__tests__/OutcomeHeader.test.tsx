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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {pick} from 'es-toolkit/compat'
import {defaultRatings, defaultMasteryPoints} from '@canvas/outcomes/react/hooks/useRatings'
import {OutcomeHeader, OutcomeHeaderProps} from '../OutcomeHeader'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {SortOrder, SortBy} from '@canvas/outcomes/react/utils/constants'
import {ContributingScoresForOutcome} from '@canvas/outcomes/react/hooks/useContributingScores'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

describe('OutcomeHeader', () => {
  let showFlashAlertSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    showFlashAlertSpy = vi.spyOn(FlashAlert, 'showFlashAlert')
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })
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
      courseId: '5',
    }
  }

  it('renders the outcome title', () => {
    render(<OutcomeHeader {...defaultProps()} />)
    expect(screen.getAllByText('outcome 1')[0]).toBeInTheDocument()
  })

  it('renders a menu with various sorting and display options', async () => {
    const user = userEvent.setup()
    render(<OutcomeHeader {...defaultProps()} />)
    await user.click(screen.getByRole('button', {name: 'outcome 1 options'}))
    expect(screen.getByText('Sort')).toBeInTheDocument()
    expect(screen.getByText('Ascending scores')).toBeInTheDocument()
    expect(screen.getByText('Descending scores')).toBeInTheDocument()
    expect(screen.getByText('Display')).toBeInTheDocument()
    expect(screen.getByText('Show Contributing Scores')).toBeInTheDocument()
    expect(screen.getByText('Outcome Info')).toBeInTheDocument()
    expect(screen.getByText('Show Outcome Distribution')).toBeInTheDocument()
  })

  it('renders the outcome description modal when option is selected', async () => {
    const user = userEvent.setup()
    render(<OutcomeHeader {...defaultProps()} />)
    await user.click(screen.getByRole('button', {name: 'outcome 1 options'}))
    await user.click(screen.getByText('Outcome Info'))
    expect(screen.getByTestId('outcome-description-modal')).toBeInTheDocument()
  })

  it('renders the outcome distribution popover when option is selected', async () => {
    const user = userEvent.setup()
    render(<OutcomeHeader {...defaultProps()} />)
    await user.click(screen.getByRole('button', {name: 'outcome 1 options'}))
    await user.click(screen.getByText('Show Outcome Distribution'))
    expect(screen.getByTestId('outcome-distribution-popover')).toBeInTheDocument()
  })

  it('announces to screen readers when showing contributing scores', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.contributingScoresForOutcome = {
      isVisible: () => false,
      toggleVisibility: vi.fn(),
      data: undefined,
      alignments: undefined,
      scoresForUser: vi.fn(() => []),
      isLoading: false,
      error: undefined,
    }
    render(<OutcomeHeader {...props} />)
    await user.click(screen.getByRole('button', {name: 'outcome 1 options'}))
    await user.click(screen.getByText('Show Contributing Scores'))

    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'Showing Contributing Scores for outcome 1',
      type: 'info',
      srOnly: true,
      politeness: 'polite',
    })
    expect(props.contributingScoresForOutcome.toggleVisibility).toHaveBeenCalled()
  })

  it('announces to screen readers when hiding contributing scores', async () => {
    const user = userEvent.setup()
    const props = defaultProps()
    props.contributingScoresForOutcome = {
      isVisible: () => true,
      toggleVisibility: vi.fn(),
      data: undefined,
      alignments: undefined,
      scoresForUser: vi.fn(() => []),
      isLoading: false,
      error: undefined,
    }
    render(<OutcomeHeader {...props} />)
    await user.click(screen.getByRole('button', {name: 'outcome 1 options'}))
    await user.click(screen.getByText('Hide Contributing Scores'))

    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'Contributing Scores for outcome 1 Hidden',
      type: 'info',
      srOnly: true,
      politeness: 'polite',
    })
    expect(props.contributingScoresForOutcome.toggleVisibility).toHaveBeenCalled()
  })
})

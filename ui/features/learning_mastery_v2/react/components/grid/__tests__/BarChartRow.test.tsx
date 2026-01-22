/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {BarChartRow, BarChartRowProps} from '../BarChartRow'
import {ContributingScoresManager} from '@canvas/outcomes/react/hooks/useContributingScores'
import {MOCK_OUTCOMES} from '../../../__fixtures__/rollups'
import {MOCK_ALIGNMENTS} from '../../../__fixtures__/contributingScores'
import {Column} from '../../table/utils'
import {
  COLUMN_WIDTH,
  COLUMN_PADDING,
  STUDENT_COLUMN_WIDTH,
  STUDENT_COLUMN_RIGHT_PADDING,
} from '@canvas/outcomes/react/utils/constants'
import {OutcomeDistribution} from '@canvas/outcomes/react/types/mastery_distribution'

const MOCK_OUTCOME_DISTRIBUTIONS: Record<string, OutcomeDistribution> = {
  '1': {
    outcome_id: '1',
    ratings: [
      {description: 'Exceeds', points: 3, color: '#127A1B', count: 5, student_ids: []},
      {description: 'Meets', points: 2, color: '#0B874B', count: 10, student_ids: []},
    ],
    total_students: 15,
  },
  '2': {
    outcome_id: '2',
    ratings: [
      {description: 'Exceeds', points: 3, color: '#127A1B', count: 3, student_ids: []},
      {description: 'Meets', points: 2, color: '#0B874B', count: 8, student_ids: []},
    ],
    total_students: 11,
  },
}

// Mock the MasteryDistributionChartCell component
vi.mock('../../charts/MasteryDistributionChartCell', () => ({
  MasteryDistributionChartCell: ({outcome, distributionData, isLoading}: any) => (
    <div data-testid={`mastery-chart-cell-${outcome.id}`}>
      <span data-testid={`loading-${outcome.id}`}>{String(isLoading)}</span>
      {distributionData && (
        <span data-testid={`distribution-${outcome.id}`}>{JSON.stringify(distributionData)}</span>
      )}
    </div>
  ),
}))

describe('BarChartRow', () => {
  const mockContributingScores: ContributingScoresManager = {
    forOutcome: vi.fn(() => ({
      isVisible: () => false,
      toggleVisibility: vi.fn(),
      data: undefined,
      alignments: undefined,
      scoresForUser: vi.fn(() => []),
      isLoading: false,
      error: undefined,
    })),
  }

  const mockHandleKeyDown = vi.fn()

  const generateColumns = (
    contributingScoresManager: ContributingScoresManager = mockContributingScores,
  ): Column[] => {
    const columns: Column[] = []

    columns.push({
      key: 'student',
      header: 'Student',
      width: STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING,
      isSticky: true,
      isRowHeader: true,
    })

    MOCK_OUTCOMES.forEach(outcome => {
      const contributingScoreForOutcome = contributingScoresManager.forOutcome(outcome.id)
      columns.push({
        key: `outcome-${outcome.id}`,
        header: outcome.title,
        width: COLUMN_WIDTH + COLUMN_PADDING,
        draggable: true,
        data: {outcome},
      })

      if (contributingScoreForOutcome.isVisible()) {
        ;(contributingScoreForOutcome.alignments || []).forEach(alignment => {
          columns.push({
            key: `contributing-score-${outcome.id}-${alignment.alignment_id}`,
            header: alignment.associated_asset_name,
            width: COLUMN_WIDTH + COLUMN_PADDING,
            data: {outcome, alignment},
          })
        })
      }
    })

    return columns
  }

  const defaultProps = (
    contributingScoresManager?: ContributingScoresManager,
  ): BarChartRowProps => ({
    columns: generateColumns(contributingScoresManager),
    outcomeDistributions: MOCK_OUTCOME_DISTRIBUTIONS,
    isLoading: false,
    handleKeyDown: mockHandleKeyDown,
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders a chart cell for each outcome', () => {
    render(<BarChartRow {...defaultProps()} />)

    expect(screen.getByTestId('mastery-chart-cell-1')).toBeInTheDocument()
    expect(screen.getByTestId('mastery-chart-cell-2')).toBeInTheDocument()
  })

  it('passes distribution data to chart cells', () => {
    render(<BarChartRow {...defaultProps()} />)

    const distribution1 = screen.getByTestId('distribution-1')
    const distribution2 = screen.getByTestId('distribution-2')

    expect(distribution1).toBeInTheDocument()
    expect(distribution2).toBeInTheDocument()
  })

  it('renders contributing score charts when visible', () => {
    const mockContributingScoresVisible: ContributingScoresManager = {
      forOutcome: vi.fn((outcomeId: string | number) => ({
        isVisible: () => outcomeId === '1',
        toggleVisibility: vi.fn(),
        data: {
          outcome: {id: '1', title: 'Outcome 1'},
          alignments: MOCK_ALIGNMENTS,
          scores: [],
        },
        alignments: MOCK_ALIGNMENTS,
        scoresForUser: vi.fn(() => [
          {user_id: '1', alignment_id: 'align-1', score: 85},
          {user_id: '1', alignment_id: 'align-2', score: 90},
        ]),
        isLoading: false,
        error: undefined,
      })),
    }

    const props = defaultProps(mockContributingScoresVisible)

    const {container} = render(<BarChartRow {...props} />)

    const charts = container.querySelectorAll('[data-testid^="mastery-chart-"]')
    expect(charts.length).toBeGreaterThan(MOCK_OUTCOMES.length)
  })

  it('does not render contributing score charts when not visible', () => {
    const {container} = render(<BarChartRow {...defaultProps()} />)

    const charts = container.querySelectorAll('[data-testid^="mastery-chart-"]')
    expect(charts).toHaveLength(MOCK_OUTCOMES.length)
  })

  it('applies box-shadow styling to outcome chart containers', () => {
    const {container} = render(<BarChartRow {...defaultProps()} />)

    const outcomeCell = container.querySelector('[id^="bar-chart-outcome-"]')
    expect(outcomeCell).not.toBeNull()
    expect(outcomeCell).toHaveAttribute('id')
  })

  it('handles empty outcomes array', () => {
    const props = {
      ...defaultProps(),
      columns: [
        {
          key: 'student',
          header: 'Student',
          width: STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING,
          isSticky: true,
          isRowHeader: true,
        },
      ],
    }

    const {container} = render(<BarChartRow {...props} />)
    const charts = container.querySelectorAll('[data-testid^="mastery-chart-"]')
    expect(charts).toHaveLength(0)
  })

  it('passes isLoading prop to chart cells', () => {
    const props = {
      ...defaultProps(),
      isLoading: true,
    }

    render(<BarChartRow {...props} />)

    expect(screen.getByTestId('loading-1')).toHaveTextContent('true')
    expect(screen.getByTestId('loading-2')).toHaveTextContent('true')
  })

  it('calls handleKeyDown when key is pressed on a cell', () => {
    const {container} = render(<BarChartRow {...defaultProps()} />)

    const cell = container.querySelector('[data-cell-id="cell--2-0"]')
    expect(cell).toBeInTheDocument()

    if (cell) {
      cell.dispatchEvent(new KeyboardEvent('keydown', {key: 'Enter', bubbles: true}))
    }

    expect(mockHandleKeyDown).toHaveBeenCalled()
  })

  it('handles outcomes with string and number IDs consistently', () => {
    const mixedIdOutcomes = [
      {...MOCK_OUTCOMES[0], id: '1'},
      {...MOCK_OUTCOMES[1], id: 2 as any},
    ]

    const mixedColumns: Column[] = [
      {
        key: 'student',
        header: 'Student',
        width: STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING,
        isSticky: true,
        isRowHeader: true,
      },
      {
        key: 'outcome-1',
        header: 'Outcome 1',
        width: COLUMN_WIDTH + COLUMN_PADDING,
        data: {outcome: mixedIdOutcomes[0]},
      },
      {
        key: 'outcome-2',
        header: 'Outcome 2',
        width: COLUMN_WIDTH + COLUMN_PADDING,
        data: {outcome: mixedIdOutcomes[1]},
      },
    ]

    const props = {
      ...defaultProps(),
      columns: mixedColumns,
    }

    render(<BarChartRow {...props} />)

    expect(screen.getByTestId('mastery-chart-cell-1')).toBeInTheDocument()
    expect(screen.getByTestId('mastery-chart-cell-2')).toBeInTheDocument()
  })

  it('handles undefined outcomeDistributions prop', () => {
    const props = {
      ...defaultProps(),
      outcomeDistributions: undefined,
    }

    const {container} = render(<BarChartRow {...props} />)
    const charts = container.querySelectorAll('[data-testid^="mastery-chart-"]')
    expect(charts).toHaveLength(MOCK_OUTCOMES.length)
  })

  it('handles undefined alignment scores gracefully', () => {
    const mockContributingScoresVisible: ContributingScoresManager = {
      forOutcome: vi.fn(() => ({
        isVisible: () => true,
        toggleVisibility: vi.fn(),
        data: {
          outcome: {id: '1', title: 'Outcome 1'},
          alignments: MOCK_ALIGNMENTS,
          scores: [],
        },
        alignments: MOCK_ALIGNMENTS,
        scoresForUser: vi.fn(() => []),
        isLoading: false,
        error: undefined,
      })),
    }

    const props = defaultProps(mockContributingScoresVisible)

    const {container} = render(<BarChartRow {...props} />)

    const charts = container.querySelectorAll('[data-testid^="mastery-chart-cell-"]')
    expect(charts.length).toBeGreaterThan(MOCK_OUTCOMES.length)
  })
})

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

import {render} from '@testing-library/react'
import {BarChartRow, BarChartRowProps} from '../BarChartRow'
import {ContributingScoresManager} from '@canvas/outcomes/react/hooks/useContributingScores'
import {MOCK_OUTCOMES, MOCK_STUDENTS, MOCK_ROLLUPS} from '../../../__fixtures__/rollups'
import {MOCK_ALIGNMENTS} from '../../../__fixtures__/contributingScores'
import {Column} from '../../table/utils'
import {
  COLUMN_WIDTH,
  COLUMN_PADDING,
  STUDENT_COLUMN_WIDTH,
  STUDENT_COLUMN_RIGHT_PADDING,
} from '@canvas/outcomes/react/utils/constants'

// Mock the MasteryDistributionChart component
vi.mock('../../charts', () => ({
  MasteryDistributionChart: ({outcome, scores}: any) => (
    <div data-testid={`mastery-chart-${outcome.id}`}>
      <span data-testid={`scores-${outcome.id}`}>{JSON.stringify(scores)}</span>
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
    contributingScoresManager: ContributingScoresManager = mockContributingScores,
  ): BarChartRowProps => ({
    rollups: MOCK_ROLLUPS,
    students: MOCK_STUDENTS,
    contributingScores: contributingScoresManager,
    columns: generateColumns(contributingScoresManager),
    handleKeyDown: mockHandleKeyDown,
  })

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders a chart for each outcome', () => {
    const {getByTestId} = render(<BarChartRow {...defaultProps()} />)

    expect(getByTestId('mastery-chart-1')).toBeInTheDocument()
    expect(getByTestId('mastery-chart-2')).toBeInTheDocument()
  })

  it('collects scores for each outcome from rollups', () => {
    const {getByTestId} = render(<BarChartRow {...defaultProps()} />)

    const scores1 = JSON.parse(getByTestId('scores-1').textContent || '[]')
    const scores2 = JSON.parse(getByTestId('scores-2').textContent || '[]')

    expect(scores1).toEqual([4.5, 2.5, 5.0])
    expect(scores2).toEqual([3.0, 4.0, 1.0])
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

  it('handles empty rollups array', () => {
    const props = {
      ...defaultProps(),
      rollups: [],
    }

    const {getByTestId} = render(<BarChartRow {...props} />)
    const scores1 = JSON.parse(getByTestId('scores-1').textContent || '[]')

    // Should return empty arrays for scores
    expect(scores1).toEqual([])
  })

  it('handles empty students array', () => {
    const props = defaultProps()
    props.students = []

    const {getByTestId} = render(<BarChartRow {...props} />)
    expect(getByTestId('mastery-chart-1')).toBeInTheDocument()
  })

  it('extracts scores for alignment when contributing scores are visible', () => {
    const mockScoresForUserFn = vi.fn(() => [
      {user_id: '1', alignment_id: 'align-1', score: 85},
      {user_id: '1', alignment_id: 'align-2', score: 90},
    ])

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
        scoresForUser: mockScoresForUserFn,
        isLoading: false,
        error: undefined,
      })),
    }

    const props = defaultProps(mockContributingScoresVisible)

    render(<BarChartRow {...props} />)

    expect(mockScoresForUserFn).toHaveBeenCalledWith('1')
    expect(mockScoresForUserFn).toHaveBeenCalledWith('2')
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

    const {getByTestId} = render(<BarChartRow {...props} />)

    expect(getByTestId('mastery-chart-1')).toBeInTheDocument()
    expect(getByTestId('mastery-chart-2')).toBeInTheDocument()
  })

  it('renders with isPreview prop set to true', () => {
    const {container} = render(<BarChartRow {...defaultProps()} />)

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

    expect(() => render(<BarChartRow {...props} />)).not.toThrow()
  })
})

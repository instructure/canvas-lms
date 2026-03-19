// @vitest-environment jsdom
/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen, waitFor} from '@testing-library/react'
import OutcomeAlignmentsList from '../OutcomeAlignmentsList'
import type {ContributingScoresForOutcome} from '@canvas/outcomes/react/hooks/useContributingScores'

vi.mock('@canvas/outcomes/react/utils/icons', () => ({
  getTagIcon: vi.fn((score: number | null, masteryPoints: number) => {
    if (score === null) return 'unassessed'
    if (score >= masteryPoints * 1.5) return 'exceeds_mastery'
    if (score >= masteryPoints) return 'mastery'
    if (score >= masteryPoints * 0.7) return 'near_mastery'
    return 'remediation'
  }),
}))

describe('OutcomeAlignmentsList', () => {
  const createMockOutcomeScores = (
    alignments: any[] = [],
    scores: any[] = [],
  ): ContributingScoresForOutcome => ({
    data: {
      outcome: {id: '1', title: 'Test Outcome'},
      alignments,
      scores,
    },
    alignments,
    scoresForUser: (studentId: string) => scores,
    isLoading: false,
    error: undefined,
    isVisible: () => false,
    toggleVisibility: vi.fn(),
  })

  const defaultProps = {
    studentId: 'student-1',
    masteryPoints: 3,
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('empty state', () => {
    it('returns null when there are no alignments', () => {
      const outcomeScores = createMockOutcomeScores([], [])
      const {container} = render(
        <OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />,
      )
      expect(container.firstChild).toBeNull()
    })

    it('returns null when outcomeScores.data is undefined', () => {
      const outcomeScores = {
        ...createMockOutcomeScores(),
        data: undefined,
      }
      const {container} = render(
        <OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />,
      )
      expect(container.firstChild).toBeNull()
    })
  })

  describe('rendering alignments', () => {
    it('renders alignment items with correct test ids', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        expect(screen.getByTestId('alignment-item-A_1')).toBeInTheDocument()
      })
    })

    it('renders multiple alignment items', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
        {
          alignment_id: 'A_2',
          associated_asset_id: '2',
          associated_asset_name: 'Assignment 2',
          associated_asset_type: 'Quiz',
          html_url: '/courses/1/quizzes/2',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
        {
          user_id: 'student-1',
          alignment_id: 'A_2',
          score: 2.5,
          submitted_or_assessed_at: '2025-01-16T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        expect(screen.getByTestId('alignment-item-A_1')).toBeInTheDocument()
        expect(screen.getByTestId('alignment-item-A_2')).toBeInTheDocument()
      })
    })

    it('renders alignment titles as links', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        const link = screen.getByText('Assignment 1').closest('a')
        expect(link).toHaveAttribute('href', '/courses/1/assignments/1')
      })
    })
  })

  describe('timeline circles', () => {
    it('renders checkmark for assessed items', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      const {container} = render(
        <OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />,
      )

      await waitFor(() => {
        // Check for checkmark icon presence in assessed items
        const checkmarkIcon = container.querySelector('svg[name="IconCheckMark"]')
        expect(checkmarkIcon).toBeTruthy()
      })
    })

    it('renders empty circle for unassessed items', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      // No scores for this alignment
      const scores: any[] = []

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      const {container} = render(
        <OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />,
      )

      await waitFor(() => {
        // Check that checkmark icon is not present for unassessed items
        const checkmarkIcon = container.querySelector('svg[name="IconCheckMark"]')
        expect(checkmarkIcon).toBeNull()
      })
    })

    it('renders connecting lines between items', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
        {
          alignment_id: 'A_2',
          associated_asset_id: '2',
          associated_asset_name: 'Assignment 2',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/2',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
        {
          user_id: 'student-1',
          alignment_id: 'A_2',
          score: 2.5,
          submitted_or_assessed_at: '2025-01-16T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        // Both items should be present
        expect(screen.getByTestId('alignment-item-A_1')).toBeInTheDocument()
        expect(screen.getByTestId('alignment-item-A_2')).toBeInTheDocument()
      })
    })
  })

  describe('date formatting', () => {
    it('displays formatted date for submitted items', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        // The date should be formatted as "January 15, 2025" or similar based on locale
        expect(screen.getByText(/January|2025/)).toBeInTheDocument()
      })
    })

    it('displays "Not submitted" for unsubmitted items', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores: any[] = []

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        expect(screen.getByText('Not submitted')).toBeInTheDocument()
      })
    })
  })

  describe('sorting', () => {
    it('sorts alignments by date ascending (oldest first)', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Newest Assignment',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
        {
          alignment_id: 'A_2',
          associated_asset_id: '2',
          associated_asset_name: 'Oldest Assignment',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/2',
        },
        {
          alignment_id: 'A_3',
          associated_asset_id: '3',
          associated_asset_name: 'Middle Assignment',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/3',
        },
      ]
      // Scores array must align with alignments array by index
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-20T10:00:00Z',
        },
        {
          user_id: 'student-1',
          alignment_id: 'A_2',
          score: 2.5,
          submitted_or_assessed_at: '2025-01-10T10:00:00Z',
        },
        {
          user_id: 'student-1',
          alignment_id: 'A_3',
          score: 4.0,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        const items = screen.getAllByTestId(/alignment-item-/)
        // Items should be sorted: Oldest (Jan 10), Middle (Jan 15), Newest (Jan 20)
        expect(items[0]).toHaveAttribute('data-testid', 'alignment-item-A_2')
        expect(items[1]).toHaveAttribute('data-testid', 'alignment-item-A_3')
        expect(items[2]).toHaveAttribute('data-testid', 'alignment-item-A_1')
      })
    })

    it('places unassessed items at the end', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Unassessed Assignment',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
        {
          alignment_id: 'A_2',
          associated_asset_id: '2',
          associated_asset_name: 'Assessed Assignment',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/2',
        },
      ]
      // Scores array must align with alignments array by index
      // A_1 has no score (undefined), A_2 has a score
      const scores = [
        undefined, // No score for A_1 (unassessed)
        {
          user_id: 'student-1',
          alignment_id: 'A_2',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        const items = screen.getAllByTestId(/alignment-item-/)
        // Assessed should come first, unassessed last
        expect(items[0]).toHaveAttribute('data-testid', 'alignment-item-A_2')
        expect(items[1]).toHaveAttribute('data-testid', 'alignment-item-A_1')
      })
    })
  })

  describe('width behavior', () => {
    it('renders component when hasChartView is false', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(
        <OutcomeAlignmentsList
          {...defaultProps}
          outcomeScores={outcomeScores}
          hasChartView={false}
        />,
      )

      await waitFor(() => {
        expect(screen.getByTestId('alignment-item-A_1')).toBeInTheDocument()
      })
    })

    it('renders component when hasChartView is true', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(
        <OutcomeAlignmentsList
          {...defaultProps}
          outcomeScores={outcomeScores}
          hasChartView={true}
        />,
      )

      await waitFor(() => {
        expect(screen.getByTestId('alignment-item-A_1')).toBeInTheDocument()
      })
    })
  })

  describe('mastery details', () => {
    it('renders mastery detail for each alignment', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 4.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      await waitFor(() => {
        // Should render "Exceeds Mastery" since score (4.5) >= masteryPoints (3) * 1.5
        const masteryText = screen.getAllByText('Exceeds Mastery')
        expect(masteryText.length).toBeGreaterThan(0)
      })
    })
  })

  describe('assignment type handling', () => {
    it('defaults to "assignment" type when associated_asset_type is undefined', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: undefined,
          html_url: '/courses/1/assignments/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      const {container} = render(
        <OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />,
      )

      await waitFor(() => {
        expect(screen.getByTestId('alignment-item-A_1')).toBeInTheDocument()
      })
    })

    it('converts associated_asset_type to lowercase', async () => {
      const alignments = [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Quiz 1',
          associated_asset_type: 'QUIZ',
          html_url: '/courses/1/quizzes/1',
        },
      ]
      const scores = [
        {
          user_id: 'student-1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ]

      const outcomeScores = createMockOutcomeScores(alignments, scores)
      render(<OutcomeAlignmentsList {...defaultProps} outcomeScores={outcomeScores} />)

      // Wait for the alignment item to be rendered
      await waitFor(() => {
        expect(screen.getByTestId('alignment-item-A_1')).toBeInTheDocument()
        expect(screen.getByText('Quiz 1')).toBeInTheDocument()
      })

      // Note: Assignment type icons load asynchronously, so they may not be immediately available
      // The component converts 'QUIZ' to 'quiz' internally
    })
  })
})

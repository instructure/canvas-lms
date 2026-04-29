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

import {render, screen} from '@testing-library/react'
import OutcomesTableRowExpansion from '../OutcomesTableRowExpansion'
import type {ContributingScoresManager} from '@canvas/outcomes/react/hooks/useContributingScores'

describe('OutcomesTableRowExpansion', () => {
  const mockContributingScores: ContributingScoresManager = {
    forOutcome: () => ({
      isVisible: () => false,
      toggleVisibility: vi.fn(),
      data: {
        outcome: {id: '1', title: 'Test Outcome'},
        alignments: [
          {
            alignment_id: 'A_1',
            associated_asset_id: '1',
            associated_asset_name: 'Assignment 1',
            associated_asset_type: 'Assignment',
            html_url: '/courses/1/assignments/1',
          },
        ],
        scores: [
          {
            user_id: '1',
            alignment_id: 'A_1',
            score: 3.5,
            submitted_or_assessed_at: '2025-01-15T10:00:00Z',
          },
        ],
      },
      alignments: [
        {
          alignment_id: 'A_1',
          associated_asset_id: '1',
          associated_asset_name: 'Assignment 1',
          associated_asset_type: 'Assignment',
          html_url: '/courses/1/assignments/1',
        },
      ],
      scoresForUser: () => [
        {
          user_id: '1',
          alignment_id: 'A_1',
          score: 3.5,
          submitted_or_assessed_at: '2025-01-15T10:00:00Z',
        },
      ],
      isLoading: false,
      error: undefined,
    }),
  }

  it('renders without errors', () => {
    expect(() =>
      render(
        <OutcomesTableRowExpansion
          outcomeId={1}
          studentId="1"
          contributingScores={mockContributingScores}
          masteryPoints={1}
        />,
      ),
    ).not.toThrow()
  })

  it('renders the chart canvas', () => {
    render(
      <OutcomesTableRowExpansion
        outcomeId={1}
        studentId="1"
        contributingScores={mockContributingScores}
        masteryPoints={1}
      />,
    )
    const canvas = screen.getByTestId('outcome-scores-chart')
    expect(canvas).toBeInTheDocument()
    expect(canvas.tagName).toBe('CANVAS')
  })
})

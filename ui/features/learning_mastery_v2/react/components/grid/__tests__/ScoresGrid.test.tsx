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
import {ScoresGrid, ScoresGridProps} from '../ScoresGrid'
import {Student, Outcome, StudentRollupData} from '../../../types/rollup'
import {ScoreDisplayFormat} from '../../../utils/constants'
import {
  ContributingScoresManager,
  ContributingScoreAlignment,
} from '../../../hooks/useContributingScores'

describe('ScoresGrid', () => {
  const mockAlignments: ContributingScoreAlignment[] = [
    {
      alignment_id: 'align-1',
      associated_asset_id: 'assignment-1',
      associated_asset_name: 'Assignment 1',
      associated_asset_type: 'Assignment',
      html_url: '/courses/123/assignments/assignment-1',
    },
    {
      alignment_id: 'align-2',
      associated_asset_id: 'assignment-2',
      associated_asset_name: 'Assignment 2',
      associated_asset_type: 'Assignment',
      html_url: '/courses/123/assignments/assignment-2',
    },
  ]

  const mockContributingScores: ContributingScoresManager = {
    forOutcome: jest.fn(() => ({
      isVisible: () => false,
      toggleVisibility: jest.fn(),
      data: undefined,
      alignments: undefined,
      scoresForUser: jest.fn(() => []),
      isLoading: false,
      error: undefined,
    })),
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  const defaultProps = (props: Partial<ScoresGridProps> = {}): ScoresGridProps => {
    return {
      rollups: [
        {
          studentId: '1',
          outcomeRollups: [
            {
              outcomeId: '1',
              score: 3,
              rating: {
                points: 3,
                color: 'green',
                description: 'mastery',
                mastery: false,
              },
            },
          ],
        },
      ] as StudentRollupData[],
      students: [
        {
          id: '1',
          name: 'Student Name',
          display_name: 'Student Name',
          status: 'active',
        },
      ] as Student[],
      outcomes: [
        {
          id: '1',
          title: 'Outcome Title',
          description: 'Outcome description',
          display_name: 'Friendly outcome name',
          calculation_method: 'decaying_average',
          calculation_int: 65,
          mastery_points: 3,
          ratings: [
            {
              points: 5,
              color: 'green',
              description: 'excellent',
              mastery: true,
            },
            {
              points: 3,
              color: 'green',
              description: 'mastery',
              mastery: false,
            },
            {
              points: 1,
              color: 'red',
              description: 'needs improvement',
              mastery: false,
            },
          ],
        },
      ] as Outcome[],
      contributingScores: mockContributingScores,
      ...props,
    }
  }

  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.GRADEBOOK_OPTIONS = {ACCOUNT_LEVEL_MASTERY_SCALES: true}
  })

  it('renders each outcome rollup', () => {
    const {getByText} = render(<ScoresGrid {...defaultProps()} />)
    expect(getByText(/mastery/)).toBeInTheDocument()
  })

  it('passes scoreDisplayFormat prop to StudentOutcomeScore components', () => {
    const {getByText} = render(
      <ScoresGrid {...defaultProps()} scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_POINTS} />,
    )
    expect(getByText('3')).toBeInTheDocument()
  })

  it('uses ICON_ONLY as default scoreDisplayFormat', () => {
    const {getByText} = render(<ScoresGrid {...defaultProps()} />)
    const srContent = getByText('mastery')
    expect(srContent).toBeInTheDocument()
  })

  it('renders correct test-id for student-outcome-score cells', () => {
    const {getByTestId} = render(<ScoresGrid {...defaultProps()} />)
    expect(getByTestId('student-outcome-score-1-1')).toBeInTheDocument()
  })

  describe('contributing scores interaction', () => {
    it('calls onOpenStudentAssignmentTray with correct parameters when score is clicked', async () => {
      const user = userEvent.setup()
      const onOpenStudentAssignmentTray = jest.fn()
      const mockContributingScoresWithData: ContributingScoresManager = {
        forOutcome: jest.fn(() => ({
          isVisible: () => true,
          toggleVisibility: jest.fn(),
          data: {
            outcome: {
              id: '1',
              title: 'Outcome Title',
            },
            alignments: mockAlignments,
            scores: [
              {
                user_id: '1',
                alignment_id: 'align-1',
                score: 85,
              },
            ],
          },
          alignments: mockAlignments,
          scoresForUser: jest.fn(() => [
            {
              user_id: '1',
              alignment_id: 'align-1',
              score: 85,
            },
          ]),
          isLoading: false,
          error: undefined,
        })),
      }

      render(
        <ScoresGrid
          {...defaultProps({
            contributingScores: mockContributingScoresWithData,
            onOpenStudentAssignmentTray,
          })}
        />,
      )

      const scoreCell = screen.getByTestId('student-outcome-score-1-1')
      const button = scoreCell.querySelector('button')
      if (button) {
        await user.click(button)
        expect(onOpenStudentAssignmentTray).toHaveBeenCalledWith(
          defaultProps().outcomes[0],
          defaultProps().students[0],
          0,
          mockAlignments,
        )
      }
    })

    it('does not render clickable button when onOpenStudentAssignmentTray is not provided', () => {
      const mockContributingScoresWithData: ContributingScoresManager = {
        forOutcome: jest.fn(() => ({
          isVisible: () => true,
          toggleVisibility: jest.fn(),
          data: {
            outcome: {
              id: '1',
              title: 'Outcome Title',
            },
            alignments: mockAlignments,
            scores: [
              {
                user_id: '1',
                alignment_id: 'align-1',
                score: 85,
              },
            ],
          },
          alignments: mockAlignments,
          scoresForUser: jest.fn(() => [
            {
              user_id: '1',
              alignment_id: 'align-1',
              score: 85,
            },
          ]),
          isLoading: false,
          error: undefined,
        })),
      }

      render(
        <ScoresGrid
          {...defaultProps({
            contributingScores: mockContributingScoresWithData,
          })}
        />,
      )

      const scoreCell = screen.getByTestId('student-outcome-score-1-1')
      const button = scoreCell.querySelector('button')
      expect(button).toBeNull()
    })
  })
})

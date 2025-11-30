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
import {render} from '@testing-library/react'
import {ScoresGrid, ScoresGridProps} from '../ScoresGrid'
import {Student, Outcome, StudentRollupData} from '../../../types/rollup'
import {ScoreDisplayFormat} from '../../../utils/constants'
import {ContributingScoresManager} from '../../../hooks/useContributingScores'

describe('ScoresGrid', () => {
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
})

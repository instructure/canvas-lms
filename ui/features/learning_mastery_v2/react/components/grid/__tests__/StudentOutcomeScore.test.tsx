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
import {StudentOutcomeScore, StudentOutcomeScoreProps} from '../StudentOutcomeScore'
import {svgUrl} from '../../../utils/icons'
import {Outcome, Rating} from '../../../types/rollup'
import {ScoreDisplayFormat} from '../../../utils/constants'

vi.mock('../../../utils/icons', () => ({
  svgUrl: vi.fn(() => 'http://test.com'),
}))

describe('StudentOutcomeScore', () => {
  interface TestProps {
    outcome?: Partial<Outcome>
    score?: number
  }

  const defaultRatings: Rating[] = [
    {
      points: 5,
      color: '#00FF00',
      description: 'excellent!',
      mastery: true,
    },
    {
      points: 3,
      color: '#FFFF00',
      description: 'great!',
      mastery: false,
    },
    {
      points: 1,
      color: '#FF0000',
      description: 'needs improvement',
      mastery: false,
    },
  ]

  const defaultProps = (props: TestProps = {}): StudentOutcomeScoreProps => {
    return {
      outcome: {
        id: '1',
        title: 'Title',
        description: 'Outcome description',
        display_name: 'Friendly outcome name',
        calculation_method: 'decaying_average',
        calculation_int: 65,
        mastery_points: 5,
        ratings: defaultRatings,
        ...props.outcome,
      } as Outcome,
      score: 'score' in props ? props.score : 3,
    }
  }

  beforeEach(() => {
    window.ENV = window.ENV || {}
    window.ENV.GRADEBOOK_OPTIONS = {
      ACCOUNT_LEVEL_MASTERY_SCALES: true,
    }
  })

  it('calls svgUrl with the right arguments', () => {
    render(<StudentOutcomeScore {...defaultProps()} />)
    expect(svgUrl).toHaveBeenCalledWith(3, 5)
  })

  it('renders ScreenReaderContent with the rating description', () => {
    const {getByText} = render(<StudentOutcomeScore {...defaultProps()} />)
    expect(getByText('great!')).toBeInTheDocument()
  })

  it('renders ScreenReaderContent with "Unassessed" if there is no score', () => {
    const {getByText} = render(<StudentOutcomeScore {...defaultProps({score: undefined})} />)
    expect(getByText('Unassessed')).toBeInTheDocument()
  })

  describe('scoreDisplayFormat', () => {
    it('renders only ScreenReaderContent with ICON_ONLY format (default)', () => {
      const {getByText} = render(<StudentOutcomeScore {...defaultProps()} />)
      const srContent = getByText('great!')
      expect(srContent).toBeInTheDocument()
      expect(srContent.closest('[class*="screenReaderContent"]')).toBeInTheDocument()
    })

    it('renders visible text with rating description when ICON_AND_LABEL format is used', () => {
      const {getByText} = render(
        <StudentOutcomeScore
          {...defaultProps()}
          scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_LABEL}
        />,
      )
      const labelText = getByText('great!')
      expect(labelText).toBeInTheDocument()
      expect(labelText.closest('[class*="screenReaderContent"]')).not.toBeInTheDocument()
    })

    it('renders visible text with score points when ICON_AND_POINTS format is used', () => {
      const {getByText} = render(
        <StudentOutcomeScore
          {...defaultProps()}
          scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_POINTS}
        />,
      )
      const pointsText = getByText('3')
      expect(pointsText).toBeInTheDocument()
      expect(pointsText.closest('[class*="screenReaderContent"]')).not.toBeInTheDocument()
    })

    it('renders "Unassessed" label when ICON_AND_LABEL format is used and no score', () => {
      const {getByText} = render(
        <StudentOutcomeScore
          {...defaultProps({score: undefined})}
          scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_LABEL}
        />,
      )
      expect(getByText('Unassessed')).toBeInTheDocument()
    })

    it('renders score when ICON_AND_POINTS format is used', () => {
      const {getByText} = render(
        <StudentOutcomeScore
          {...defaultProps({score: 2.5})}
          scoreDisplayFormat={ScoreDisplayFormat.ICON_AND_POINTS}
        />,
      )
      expect(getByText('2.5')).toBeInTheDocument()
    })
  })
})

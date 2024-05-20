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
import StudentOutcomeScore from '../StudentOutcomeScore'
import {svgUrl} from '../icons'

jest.mock('../icons', () => ({
  svgUrl: jest.fn(() => 'http://test.com'),
}))

describe('StudentOutcomeScore', () => {
  const defaultProps = (props = {}) => {
    return {
      outcome: {
        id: '1',
        title: 'Title',
        description: 'Outcome description',
        display_name: 'Friendly outcome name',
        calculation_method: 'decaying_average',
        calculation_int: 65,
        mastery_points: 5,
        ratings: [],
      },
      rollup: {
        outcomeId: '1',
        rating: {
          color: 'FFFFF',
          points: 3,
          description: 'great!',
          mastery: false,
        },
      },
      visibleRatings: [true, true, true, true, true, true],
      ...props,
    }
  }

  beforeEach(() => {
    window.ENV = {GRADEBOOK_OPTIONS: {ACCOUNT_LEVEL_MASTERY_SCALES: true}}
  })

  it('calls svgUrl with the right arguments', () => {
    render(<StudentOutcomeScore {...defaultProps()} />)
    expect(svgUrl).toHaveBeenCalledWith(3, 5)
  })

  it('renders ScreenReaderContent with the rating description', () => {
    const {getByText} = render(<StudentOutcomeScore {...defaultProps()} />)
    expect(getByText('great!')).toBeInTheDocument()
  })

  it('renders ScreenReaderContent with "Unassessed" if there is no rollup rating', () => {
    const {getByText} = render(
      <StudentOutcomeScore
        {...defaultProps({
          rollup: {
            outcomeId: '1',
            rating: {points: 3, color: 'FFFFF', description: '', mastery: false},
          },
        })}
      />
    )
    expect(getByText('Unassessed')).toBeInTheDocument()
  })

  it('does not render score if rating is not visible', () => {
    const {queryByText} = render(
      <StudentOutcomeScore
        {...defaultProps({
          visibleRatings: [true, true, true, true, false, true],
        })}
      />
    )
    expect(queryByText('great!')).toBeNull()
  })
})

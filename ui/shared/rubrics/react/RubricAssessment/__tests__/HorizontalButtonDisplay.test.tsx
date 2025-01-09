/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {HorizontalButtonDisplay} from '../HorizontalButtonDisplay'
import type {RubricRating} from '../../types/rubric'

const mockRatings: RubricRating[] = [
  {
    id: '1',
    description: 'Full Marks',
    longDescription: 'Student demonstrates excellent understanding',
    points: 5,
  },
  {
    id: '2',
    description: 'Partial Marks',
    longDescription: 'Student demonstrates partial understanding',
    points: 3,
  },
  {
    id: '3',
    description: 'No Marks',
    longDescription: 'Student demonstrates no understanding',
    points: 0,
  },
]

describe('HorizontalButtonDisplay', () => {
  const defaultProps = {
    isPreviewMode: false,
    ratings: mockRatings,
    ratingOrder: 'descending',
    onSelectRating: jest.fn(),
    criterionUseRange: false,
    isSelfAssessment: false,
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders all rating buttons', () => {
    render(<HorizontalButtonDisplay {...defaultProps} />)

    mockRatings.forEach((rating, index) => {
      expect(screen.getByTestId(`rating-button-${rating.id}-${index}`)).toBeInTheDocument()
    })
  })

  it('displays rating details when a rating is selected', () => {
    render(<HorizontalButtonDisplay {...defaultProps} selectedRatingId="1" />)

    const ratingDetails = screen.getByTestId('rating-details-1')
    expect(ratingDetails).toBeInTheDocument()
    expect(ratingDetails).toHaveTextContent('Full Marks')
    expect(ratingDetails).toHaveTextContent('Student demonstrates excellent understanding')
    expect(ratingDetails).toHaveTextContent('5 pts')
  })

  it('calls onSelectRating when a rating button is clicked', async () => {
    const user = userEvent.setup()
    render(<HorizontalButtonDisplay {...defaultProps} />)

    const ratingButton = screen.getByTestId('rubric-rating-button-2')
    await user.click(ratingButton)

    expect(defaultProps.onSelectRating).toHaveBeenCalledWith(mockRatings[0])
  })

  it('renders ratings in ascending order when specified', () => {
    render(<HorizontalButtonDisplay {...defaultProps} ratingOrder="ascending" />)

    const ratingButtons = screen.getAllByTestId(/^rating-button-/)
    expect(ratingButtons[ratingButtons.length - 1].getAttribute('aria-label')).toContain('No Marks')
    expect(ratingButtons[0].getAttribute('aria-label')).toContain('Full Marks')
  })

  it('shows point range when criterionUseRange is true', () => {
    render(
      <HorizontalButtonDisplay {...defaultProps} criterionUseRange={true} selectedRatingId="2" />,
    )

    const ratingDetails = screen.getByTestId('rating-details-2')
    expect(ratingDetails).toHaveTextContent('0.1 to 3 pts')
  })

  it('shows exact points when criterionUseRange is false', () => {
    render(
      <HorizontalButtonDisplay {...defaultProps} criterionUseRange={false} selectedRatingId="2" />,
    )

    const ratingDetails = screen.getByTestId('rating-details-2')
    expect(ratingDetails).toHaveTextContent('3 pts')
  })
})

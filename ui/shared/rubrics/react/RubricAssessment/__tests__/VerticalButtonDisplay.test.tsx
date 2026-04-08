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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {VerticalButtonDisplay} from '../VerticalButtonDisplay'
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

describe('VerticalButtonDisplay', () => {
  const defaultProps = {
    buttonDisplay: 'numeric',
    criterionId: 'criterion-1',
    isPreviewMode: false,
    ratings: mockRatings,
    ratingOrder: 'descending',
    onSelectRating: vi.fn(),
    criterionUseRange: false,
    isSelfAssessment: false,
    hidePoints: false,
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders all rating buttons', () => {
    render(<VerticalButtonDisplay {...defaultProps} />)

    mockRatings.forEach((rating, index) => {
      expect(screen.getByTestId(`rating-button-${rating.id}-${index}`)).toBeInTheDocument()
    })
  })

  it('displays rating details when a rating is selected', () => {
    render(<VerticalButtonDisplay {...defaultProps} selectedRatingId="1" />)

    const ratingDetails = screen.getByTestId('rating-details-1')
    expect(ratingDetails).toBeInTheDocument()
    expect(ratingDetails).toHaveTextContent('Full Marks')
    expect(ratingDetails).toHaveTextContent('Student demonstrates excellent understanding')
    expect(ratingDetails).toHaveTextContent('5 pts')
  })

  it('calls onSelectRating when a rating button is clicked', async () => {
    const user = userEvent.setup()
    render(<VerticalButtonDisplay {...defaultProps} />)

    const ratingButton = screen.getByTestId('rubric-rating-button-2')
    await user.click(ratingButton)

    expect(defaultProps.onSelectRating).toHaveBeenCalledWith(mockRatings[0])
  })

  it('renders ratings in ascending order when specified', () => {
    render(<VerticalButtonDisplay {...defaultProps} ratingOrder="ascending" />)

    const buttons = screen.getAllByTestId(/^rubric-rating-button-\d+$/)
    expect(buttons[0]).toHaveAccessibleName(/Full Marks/)
    expect(buttons[buttons.length - 1]).toHaveAccessibleName(/No Marks/)
  })

  it('shows point range when criterionUseRange is true', () => {
    render(
      <VerticalButtonDisplay {...defaultProps} criterionUseRange={true} selectedRatingId="2" />,
    )

    const ratingDetails = screen.getByTestId('rating-details-2')
    expect(ratingDetails).toHaveTextContent('3 to >0 pts')
  })

  it('shows exact points when criterionUseRange is false', () => {
    render(
      <VerticalButtonDisplay {...defaultProps} criterionUseRange={false} selectedRatingId="2" />,
    )

    const ratingDetails = screen.getByTestId('rating-details-2')
    expect(ratingDetails).toHaveTextContent('3 pts')
  })

  it('does not show points when hidePoints is true', () => {
    render(<VerticalButtonDisplay {...defaultProps} selectedRatingId="1" hidePoints={true} />)

    const ratingDetails = screen.getByTestId('rating-details-1')
    expect(ratingDetails).toBeInTheDocument()
    expect(ratingDetails).toHaveTextContent('Full Marks')
    expect(ratingDetails).toHaveTextContent('Student demonstrates excellent understanding')
    expect(ratingDetails).not.toHaveTextContent('5 pts')
  })

  it('rating buttons have correct accessible name with rating description', () => {
    render(<VerticalButtonDisplay {...defaultProps} />)

    // With 3 ratings, buttonLabel is (length - index - 1): Full Marks=2, Partial Marks=1
    expect(screen.getByTestId('rubric-rating-button-2')).toHaveAccessibleName(/Full Marks/)
    expect(screen.getByTestId('rubric-rating-button-1')).toHaveAccessibleName(/Partial Marks/)
  })

  it('accessible name has no double spaces when longDescription is empty', () => {
    const ratingsWithEmptyDesc = [{...mockRatings[0], longDescription: ''}]
    render(<VerticalButtonDisplay {...defaultProps} ratings={ratingsWithEmptyDesc} />)

    // With 1 rating, buttonLabel is (1 - 0 - 1) = 0
    expect(screen.getByTestId('rubric-rating-button-0')).toHaveAccessibleName(/^Full Marks 5 pts/)
  })
})

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

import {render, screen, fireEvent} from '@testing-library/react'
import {TraditionalViewCriterionRating} from '../TraditionalViewCriterionRating'
import type {RubricRating} from '../../types/rubric'
import {ProficiencyRating} from '@canvas/graphql/codegen/graphql'

describe('TraditionalViewCriterionRating', () => {
  const defaultRating: RubricRating = {
    id: 'rating-1',
    description: 'Excellent',
    longDescription: 'Outstanding work',
    points: 10,
  }

  const defaultProps = {
    criterionId: 'criterion-1',
    criterionPointsPossible: 10,
    hidePoints: false,
    index: 0,
    isHovered: false,
    isLastRating: false,
    isPreviewMode: false,
    isSelected: false,
    isSelfAssessmentSelected: false,
    rating: defaultRating,
    ratingCellMinWidth: '150px',
    elementRef: vi.fn(),
    onClickRating: vi.fn(),
    setHoveredRatingIndex: vi.fn(),
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  describe('rendering', () => {
    it('should render rating description', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} />)
      expect(screen.getByText('Excellent')).toBeInTheDocument()
    })

    it('should render rating long description', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} />)
      expect(screen.getByText('Outstanding work')).toBeInTheDocument()
    })

    it('should render rating points', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} />)
      expect(
        screen.getByTestId('traditional-criterion-criterion-1-ratings-0-points'),
      ).toHaveTextContent('10 pts')
    })

    it('should hide points when hidePoints is true', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} hidePoints={true} />)
      expect(
        screen.getByTestId('traditional-criterion-criterion-1-ratings-0-points'),
      ).toHaveTextContent('')
    })

    it('should render with button testid', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} />)
      expect(screen.getByTestId('traditional-criterion-criterion-1-ratings-0')).toBeInTheDocument()
    })
  })

  describe('points display', () => {
    it('should display points range when min is provided', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} min={5} />)
      expect(
        screen.getByTestId('traditional-criterion-criterion-1-ratings-0-points'),
      ).toHaveTextContent('5 to 10 pts')
    })

    it('should display single point value when min is not provided', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} />)
      expect(
        screen.getByTestId('traditional-criterion-criterion-1-ratings-0-points'),
      ).toHaveTextContent('10 pts')
    })
  })

  describe('selection indicator', () => {
    it('should show selection triangle when isSelected is true', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} isSelected={true} />)
      expect(
        screen.getByTestId('traditional-criterion-criterion-1-ratings-0-selected'),
      ).toBeInTheDocument()
    })

    it('should not show selection triangle when isSelected is false', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} />)
      expect(
        screen.queryByTestId('traditional-criterion-criterion-1-ratings-0-selected'),
      ).not.toBeInTheDocument()
    })

    it('should show dashed border when isSelfAssessmentSelected is true', () => {
      const {container} = render(
        <TraditionalViewCriterionRating {...defaultProps} isSelfAssessmentSelected={true} />,
      )
      const dashedBorder = container.querySelector('[style*="border: 2px dashed"]')
      expect(dashedBorder).toBeInTheDocument()
    })
  })

  describe('custom rating colors', () => {
    const customRatings: ProficiencyRating[] = [
      {
        _id: '1',
        description: 'Mastery',
        points: 10,
        color: '00ff00',
        mastery: true,
      },
      {
        _id: '2',
        description: 'Proficient',
        points: 7,
        color: 'ffff00',
        mastery: false,
      },
      {
        _id: '3',
        description: 'Developing',
        points: 4,
        color: 'ff0000',
        mastery: false,
      },
    ]

    it('should use custom rating color when customRatings are provided', () => {
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          rating={{...defaultRating, points: 10}}
          customRatings={customRatings}
          isSelected={true}
        />,
      )
      const selectedTriangle = screen.getByTestId(
        'traditional-criterion-criterion-1-ratings-0-selected',
      )
      expect(selectedTriangle).toBeInTheDocument()
      // The selection triangle should use the custom color for 10 points (green)
      expect(selectedTriangle).toHaveStyle('border-bottom: 12px solid #00ff00')
    })

    it('should use appropriate color for mid-range points', () => {
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          rating={{...defaultRating, points: 7}}
          customRatings={customRatings}
          isSelected={true}
        />,
      )
      const selectedTriangle = screen.getByTestId(
        'traditional-criterion-criterion-1-ratings-0-selected',
      )
      expect(selectedTriangle).toBeInTheDocument()
      // The selection triangle should use the custom color for 7 points (yellow)
      expect(selectedTriangle).toHaveStyle('border-bottom: 12px solid #ffff00')
    })

    it('should use appropriate color for low points', () => {
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          rating={{...defaultRating, points: 4}}
          customRatings={customRatings}
          isSelected={true}
        />,
      )
      const selectedTriangle = screen.getByTestId(
        'traditional-criterion-criterion-1-ratings-0-selected',
      )
      expect(selectedTriangle).toBeInTheDocument()
      // The selection triangle should use the custom color for 4 points (red)
      expect(selectedTriangle).toHaveStyle('border-bottom: 12px solid #ff0000')
    })

    it('should fall back to lowest rating color when points are below all thresholds', () => {
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          rating={{...defaultRating, points: 1}} // Points below the lowest custom rating
          customRatings={customRatings}
          isSelected={true}
        />,
      )
      const selectedTriangle = screen.getByTestId(
        'traditional-criterion-criterion-1-ratings-0-selected',
      )
      expect(selectedTriangle).toBeInTheDocument()
      // Should fall back to the lowest rating color (red - Developing)
      expect(selectedTriangle).toHaveStyle('border-bottom: 12px solid #ff0000')
    })

    it('should use default green color when no customRatings are provided', () => {
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          rating={{...defaultRating, points: 10}}
          isSelected={true}
        />,
      )
      const selectedTriangle = screen.getByTestId(
        'traditional-criterion-criterion-1-ratings-0-selected',
      )
      expect(selectedTriangle).toBeInTheDocument()
      // Should use default Canvas green color
      expect(selectedTriangle).toHaveStyle('border-bottom: 12px solid #03893D')
    })
  })

  describe('preview mode', () => {
    it('should disable button when isPreviewMode is true', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} isPreviewMode={true} />)
      const button = screen.getByTestId('traditional-criterion-criterion-1-ratings-0')
      expect(button).toBeDisabled()
    })

    it('should enable button when isPreviewMode is false', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} isPreviewMode={false} />)
      const button = screen.getByTestId('traditional-criterion-criterion-1-ratings-0')
      expect(button).not.toBeDisabled()
    })

    it('should not set hover index when hovering in preview mode', () => {
      const setHoveredRatingIndex = vi.fn()
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          isPreviewMode={true}
          setHoveredRatingIndex={setHoveredRatingIndex}
        />,
      )
      const button = screen.getByTestId('traditional-criterion-criterion-1-ratings-0')
      fireEvent.mouseOver(button)
      expect(setHoveredRatingIndex).toHaveBeenCalledWith(-1)
    })
  })

  describe('interactions', () => {
    it('should call onClickRating when button is clicked', () => {
      const onClickRating = vi.fn()
      render(<TraditionalViewCriterionRating {...defaultProps} onClickRating={onClickRating} />)
      const button = screen.getByTestId('traditional-criterion-criterion-1-ratings-0')
      fireEvent.click(button)
      expect(onClickRating).toHaveBeenCalledWith('rating-1')
    })

    it('should call setHoveredRatingIndex on mouse over', () => {
      const setHoveredRatingIndex = vi.fn()
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          setHoveredRatingIndex={setHoveredRatingIndex}
        />,
      )
      const button = screen.getByTestId('traditional-criterion-criterion-1-ratings-0')
      fireEvent.mouseOver(button)
      expect(setHoveredRatingIndex).toHaveBeenCalledWith(0)
    })

    it('should call setHoveredRatingIndex with undefined on mouse out', () => {
      const setHoveredRatingIndex = vi.fn()
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          setHoveredRatingIndex={setHoveredRatingIndex}
        />,
      )
      const button = screen.getByTestId('traditional-criterion-criterion-1-ratings-0')
      fireEvent.mouseOut(button)
      expect(setHoveredRatingIndex).toHaveBeenCalledWith(undefined)
    })

    it('should call elementRef with element', () => {
      const elementRef = vi.fn()
      render(<TraditionalViewCriterionRating {...defaultProps} elementRef={elementRef} />)
      expect(elementRef).toHaveBeenCalled()
    })
  })

  describe('screen reader content', () => {
    it('should announce when rating is selected', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} isSelected={true} />)
      expect(screen.getByText('Selected')).toBeInTheDocument()
    })

    it('should announce when rating is self-assessment selected', () => {
      render(<TraditionalViewCriterionRating {...defaultProps} isSelfAssessmentSelected={true} />)
      expect(screen.getByText('Self Assessment')).toBeInTheDocument()
    })

    it('should announce both when both selected', () => {
      render(
        <TraditionalViewCriterionRating
          {...defaultProps}
          isSelected={true}
          isSelfAssessmentSelected={true}
        />,
      )
      expect(screen.getByText('Selected and Self Assessment')).toBeInTheDocument()
    })
  })
})

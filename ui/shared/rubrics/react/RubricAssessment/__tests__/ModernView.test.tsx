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
import {render, screen, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {ModernView} from '../ModernView'
import type {RubricCriterion, RubricAssessmentData} from '../../types/rubric'

const mockCriteria: RubricCriterion[] = [
  {
    id: 'criterion_1',
    description: 'Writing Quality',
    longDescription: 'Evaluate the clarity and effectiveness of writing',
    points: 10,
    criterionUseRange: false,
    ignoreForScoring: false,
    ratings: [
      {
        id: 'rating_1_1',
        description: 'Excellent',
        longDescription: 'Clear and effective writing throughout',
        points: 10,
      },
      {
        id: 'rating_1_2',
        description: 'Good',
        longDescription: 'Generally clear and effective writing',
        points: 8,
      },
    ],
  },
  {
    id: 'criterion_2',
    description: 'Content Understanding',
    longDescription: 'Demonstrates understanding of core concepts',
    points: 5,
    criterionUseRange: true,
    learningOutcomeId: 'outcome_1',
    masteryPoints: 3,
    ignoreForScoring: false,
    ratings: [
      {
        id: 'rating_2_1',
        description: 'Complete',
        longDescription: 'Shows full understanding',
        points: 5,
      },
      {
        id: 'rating_2_2',
        description: 'Partial',
        longDescription: 'Shows some understanding',
        points: 3,
      },
    ],
  },
  {
    id: 'criterion_3',
    description: 'Application of Knowledge',
    longDescription: 'Applies knowledge to practical scenarios',
    points: 0,
    criterionUseRange: true,
    masteryPoints: 0,
    ignoreForScoring: false,
    ratings: [
      {
        id: 'rating_3_1',
        description: 'Excellent',
        longDescription: 'Applies knowledge effectively',
        points: 0,
      },
      {
        id: 'rating_3_2',
        description: 'Good',
        longDescription: 'Applies knowledge with minor errors',
        points: 0,
      },
      {
        id: 'rating_3_3',
        description: 'Fair',
        longDescription: 'Applies knowledge with some errors',
        points: 0,
      },
    ],
  },
]

const mockRubricAssessmentData: RubricAssessmentData[] = [
  {
    criterionId: 'criterion_1',
    points: 10,
    comments: 'Good work on the writing',
    id: 'rating_1_2',
    commentsEnabled: true,
    description: 'Excellent',
    ignoreForScoring: false,
  },
  {
    criterionId: 'criterion_3',
    points: 0,
    comments: '',
    id: 'rating_3_2',
    commentsEnabled: true,
    description: 'Excellent',
    ignoreForScoring: false,
  },
]

describe('ModernView', () => {
  const defaultProps = {
    buttonDisplay: 'numeric',
    criteria: mockCriteria,
    hidePoints: false,
    isPreviewMode: false,
    isPeerReview: false,
    isSelfAssessment: false,
    isFreeFormCriterionComments: false,
    ratingOrder: 'descending',
    rubricAssessmentData: mockRubricAssessmentData,
    selectedViewMode: 'horizontal' as const,
    onUpdateAssessmentData: vi.fn(),
  }

  const renderModernView = (props = {}) => {
    return render(
      <MockedQueryProvider>
        <ModernView {...defaultProps} {...props} />
      </MockedQueryProvider>,
    )
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders criteria descriptions and ratings', () => {
    renderModernView()

    mockCriteria.forEach(criterion => {
      if (criterion.description) {
        const descriptions = screen.getAllByText(criterion.description)
        expect(descriptions.length).toBeGreaterThan(0)
      }

      if (criterion.longDescription) {
        const longDescriptions = screen.getAllByText(criterion.longDescription)
        expect(longDescriptions.length).toBeGreaterThan(0)
      }

      criterion.ratings.forEach((rating, index) => {
        // Find rating button by data-testid which includes rating ID and index
        expect(screen.getByTestId(`rating-button-${rating.id}-${index}`)).toBeInTheDocument()
      })
    })
  })

  it('displays outcome tag for criteria with learning outcomes', () => {
    renderModernView()

    const outcomeElements = screen.getAllByText('Content Understanding')
    expect(outcomeElements.length).toBeGreaterThan(0)
    expect(screen.getByText('Threshold: 3 pts')).toBeInTheDocument()
  })

  it('shows existing assessment data', () => {
    renderModernView()

    const assessment = mockRubricAssessmentData[0]
    const pointsInput = screen.getByTestId(`criterion-score-${assessment.criterionId}`)
    expect(pointsInput).toHaveValue('10')
    expect(screen.getByText(assessment.comments)).toBeInTheDocument()
  })

  it('allows selecting a rating', async () => {
    const user = userEvent.setup()
    renderModernView()

    const criterion = mockCriteria[0]
    const nextRating = criterion.ratings[0]
    const currentRating = criterion.ratings[1]
    // Find rating button by data-testid which includes rating ID and index
    const ratingButton = screen.getByTestId(`rating-button-${nextRating.id}-0`)
    await user.click(ratingButton.querySelector('button') as HTMLElement)

    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledWith({
      comments: mockRubricAssessmentData[0].comments,
      commentsEnabled: mockRubricAssessmentData[0].commentsEnabled,
      criterionId: criterion.id,
      description: nextRating.description,
      id: currentRating.id,
      ignoreForScoring: mockRubricAssessmentData[0].ignoreForScoring,
      points: nextRating.points,
      ratingId: nextRating.id,
    })
  })

  it('allows entering points directly', async () => {
    const user = userEvent.setup()
    renderModernView()

    const pointsInput = screen.getByTestId('criterion-score-criterion_1')
    await user.clear(pointsInput)
    await user.type(pointsInput, '7')
    await user.tab() // Trigger blur event

    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledWith({
      ...mockRubricAssessmentData[0],
      criterionId: 'criterion_1',
      points: 7,
      ratingId: undefined,
    })
  })

  it('disables interactions in preview mode', () => {
    renderModernView({isPreviewMode: true})

    // Points input is replaced with text in preview mode
    const pointsText = screen.getByText('10')
    expect(pointsText).toBeInTheDocument()

    // Rating buttons should be disabled
    const ratingButtons = screen.getAllByTestId(/^rating-button-rating_\d+_\d+-\d+$/)
    ratingButtons.forEach(button => {
      const buttonElement = button.querySelector('button')
      expect(buttonElement).toBeDisabled()
    })
  })

  it('switches between horizontal and vertical views', () => {
    const {rerender} = renderModernView({selectedViewMode: 'horizontal'})
    expect(screen.getAllByTestId('rubric-assessment-horizontal-display')).toHaveLength(
      mockCriteria.length,
    )

    rerender(
      <MockedQueryProvider>
        <ModernView {...defaultProps} selectedViewMode="vertical" />
      </MockedQueryProvider>,
    )
    expect(screen.getAllByTestId('rubric-assessment-vertical-display')).toHaveLength(
      mockCriteria.length,
    )
  })

  it('displays validation errors', () => {
    const validationErrors = ['criterion_1']
    renderModernView({validationErrors})

    expect(screen.getByText('Please select a rating or enter a score')).toBeInTheDocument()
  })

  it('shows comment input field and allows typing', async () => {
    const user = userEvent.setup()
    renderModernView()

    const commentInput = screen.getByTestId('comment-text-area-criterion_1')
    await user.clear(commentInput)
    await user.type(commentInput, 'Test comment')
    await user.tab() // Trigger blur event

    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledWith({
      ...mockRubricAssessmentData[0],
      criterionId: 'criterion_1',
      comments: 'Test comment',
      ratingId: mockRubricAssessmentData[0].id,
    })
  })

  it(`comment blur does not clear rating for criterion where ratings' points are different`, async () => {
    renderModernView()

    const commentInput = screen.getByTestId('comment-text-area-criterion_1')
    fireEvent.blur(commentInput)

    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledWith({
      ...mockRubricAssessmentData[0],
      ratingId: mockRubricAssessmentData[0].id,
    })
    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledTimes(1)
  })

  it(`comment blur does not clear rating for criterion where ratings' points are equal`, async () => {
    renderModernView()

    const commentInput = screen.getByTestId('comment-text-area-criterion_3')
    fireEvent.blur(commentInput)

    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledWith({
      ...mockRubricAssessmentData[1],
      ratingId: mockRubricAssessmentData[1].id,
    })
    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledTimes(1)
  })

  describe('buttonDisplay tests', () => {
    it('renders numeric button displays by default for horizontal view', () => {
      renderModernView({selectedViewMode: 'horizontal'})

      const ratingButtons = screen.getAllByTestId('rubric-rating-button-label')
      const totalRatings = mockCriteria.reduce(
        (sum, criterion) => sum + criterion.ratings.length,
        0,
      )
      expect(ratingButtons).toHaveLength(totalRatings)
      const innerText = ratingButtons.map(btn => btn.innerText)

      //criteria 1
      expect(innerText[0]).toEqual('1')
      expect(innerText[1]).toEqual('0')

      //criteria 2
      expect(innerText[2]).toEqual('1')
      expect(innerText[3]).toEqual('0')

      //criteria 3
      expect(innerText[4]).toEqual('2')
      expect(innerText[5]).toEqual('1')
      expect(innerText[6]).toEqual('0')
    })

    it('renders numeric button displays by default for vertical view', () => {
      renderModernView({selectedViewMode: 'vertical'})

      const ratingButtons = screen.getAllByTestId('rubric-rating-button-label')
      const totalRatings = mockCriteria.reduce(
        (sum, criterion) => sum + criterion.ratings.length,
        0,
      )
      expect(ratingButtons).toHaveLength(totalRatings)
      const innerText = ratingButtons.map(btn => btn.innerText)

      //criteria 1
      expect(innerText[0]).toEqual('1')
      expect(innerText[1]).toEqual('0')

      //criteria 2
      expect(innerText[2]).toEqual('1')
      expect(innerText[3]).toEqual('0')

      //criteria 3
      expect(innerText[4]).toEqual('2')
      expect(innerText[5]).toEqual('1')
      expect(innerText[6]).toEqual('0')
    })

    it('renders points button displays for horizontal view', () => {
      renderModernView({selectedViewMode: 'horizontal', buttonDisplay: 'points'})

      const ratingButtons = screen.getAllByTestId('rubric-rating-button-label')
      const totalRatings = mockCriteria.reduce(
        (sum, criterion) => sum + criterion.ratings.length,
        0,
      )
      expect(ratingButtons).toHaveLength(totalRatings)
      const innerText = ratingButtons.map(btn => btn.innerText)

      //criteria 1
      expect(innerText[0]).toEqual('10')
      expect(innerText[1]).toEqual('8')

      // criteria 2
      expect(innerText[2]).toEqual('5')
      expect(innerText[3]).toEqual('3')

      // criteria 3
      expect(innerText[4]).toEqual('0')
      expect(innerText[5]).toEqual('0')
      expect(innerText[6]).toEqual('0')
    })

    it('renders points button displays for vertical view', () => {
      renderModernView({selectedViewMode: 'vertical', buttonDisplay: 'points'})

      const ratingButtons = screen.getAllByTestId('rubric-rating-button-label')
      const totalRatings = mockCriteria.reduce(
        (sum, criterion) => sum + criterion.ratings.length,
        0,
      )
      expect(ratingButtons).toHaveLength(totalRatings)
      const innerText = ratingButtons.map(btn => btn.innerText)

      //criteria 1
      expect(innerText[0]).toEqual('10')
      expect(innerText[1]).toEqual('8')

      // criteria 2
      expect(innerText[2]).toEqual('5')
      expect(innerText[3]).toEqual('3')

      // criteria 3
      expect(innerText[4]).toEqual('0')
      expect(innerText[5]).toEqual('0')
      expect(innerText[6]).toEqual('0')
    })

    it('does not renders points button displays for horizontal view when hidePoints is true', () => {
      renderModernView({selectedViewMode: 'horizontal', buttonDisplay: 'points', hidePoints: true})

      const ratingButtons = screen.getAllByTestId('rubric-rating-button-label')
      const totalRatings = mockCriteria.reduce(
        (sum, criterion) => sum + criterion.ratings.length,
        0,
      )
      expect(ratingButtons).toHaveLength(totalRatings)
      const innerText = ratingButtons.map(btn => btn.innerText)

      //criteria 1
      expect(innerText[0]).toEqual('1')
      expect(innerText[1]).toEqual('0')

      //criteria 2
      expect(innerText[2]).toEqual('1')
      expect(innerText[3]).toEqual('0')

      //criteria 3
      expect(innerText[4]).toEqual('2')
      expect(innerText[5]).toEqual('1')
      expect(innerText[6]).toEqual('0')
    })

    it('does not renders points button displays for vertical view when hidePoints is true', () => {
      renderModernView({selectedViewMode: 'vertical', buttonDisplay: 'points', hidePoints: true})

      const ratingButtons = screen.getAllByTestId('rubric-rating-button-label')
      const totalRatings = mockCriteria.reduce(
        (sum, criterion) => sum + criterion.ratings.length,
        0,
      )
      expect(ratingButtons).toHaveLength(totalRatings)
      const innerText = ratingButtons.map(btn => btn.innerText)

      //criteria 1
      expect(innerText[0]).toEqual('1')
      expect(innerText[1]).toEqual('0')

      //criteria 2
      expect(innerText[2]).toEqual('1')
      expect(innerText[3]).toEqual('0')

      //criteria 3
      expect(innerText[4]).toEqual('2')
      expect(innerText[5]).toEqual('1')
      expect(innerText[6]).toEqual('0')
    })
  })
})

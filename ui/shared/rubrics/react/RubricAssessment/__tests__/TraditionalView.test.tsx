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
import {fireEvent, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {TraditionalView} from '../TraditionalView'
import type {RubricCriterion, RubricAssessmentData} from '../../types/rubric'

// Mock AiUsageButton component
vi.mock('../../components/AiUsageButton', () => {
  return {
    __esModule: true,
    default: () => <button data-testid="ai-usage-button">AI Assisted</button>,
  }
})

const defaultCriteria: RubricCriterion[] = [
  {
    id: 'criterion_1',
    description: 'First Criterion',
    longDescription: 'Detailed description of first criterion',
    points: 5,
    learningOutcomeId: undefined,
    masteryPoints: undefined,
    ignoreForScoring: false,
    criterionUseRange: false,
    ratings: [
      {
        id: 'rating_1_1',
        description: 'Full Marks',
        longDescription: 'Student demonstrates excellent understanding',
        points: 5,
      },
      {
        id: 'rating_1_2',
        description: 'Partial Marks',
        longDescription: 'Student demonstrates partial understanding',
        points: 3,
      },
    ],
  },
  {
    id: 'criterion_2',
    description: 'Application of Knowledge',
    longDescription: 'Applies knowledge to practical scenarios',
    points: 0,
    criterionUseRange: true,
    masteryPoints: 0,
    ignoreForScoring: false,
    ratings: [
      {
        id: 'rating_2_1',
        description: 'Excellent',
        longDescription: 'Applies knowledge effectively',
        points: 0,
      },
      {
        id: 'rating_2_2',
        description: 'Good',
        longDescription: 'Applies knowledge with minor errors',
        points: 0,
      },
      {
        id: 'rating_2_3',
        description: 'Fair',
        longDescription: 'Applies knowledge with some errors',
        points: 0,
      },
    ],
  },
]

const defaultAssessmentData: RubricAssessmentData[] = [
  {
    criterionId: 'criterion_1',
    points: 5,
    comments: '',
    id: 'rating_1_1',
    commentsEnabled: true,
    description: 'Full Marks',
  },
  {
    criterionId: 'criterion_2',
    points: 0,
    comments: '',
    id: 'rating_2_2',
    commentsEnabled: true,
    description: 'Excellent',
    ignoreForScoring: false,
  },
]

describe('TraditionalView', () => {
  const defaultProps = {
    criteria: defaultCriteria,
    hidePoints: false,
    isPreviewMode: false,
    isFreeFormCriterionComments: false,
    ratingOrder: 'descending',
    rubricAssessmentData: defaultAssessmentData,
    rubricTitle: 'Test Rubric',
    onUpdateAssessmentData: vi.fn(),
  }

  const renderTraditionalView = (props = {}) => {
    return render(
      <MockedQueryProvider>
        <TraditionalView {...defaultProps} {...props} />
      </MockedQueryProvider>,
    )
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the rubric title', () => {
    renderTraditionalView()
    expect(screen.getAllByText('Test Rubric')).toHaveLength(2)
  })

  it('renders without points when hidePoints is true', () => {
    renderTraditionalView({hidePoints: true})
    expect(screen.queryByText('5 pts')).not.toBeInTheDocument()
  })

  it('renders in preview mode correctly', () => {
    renderTraditionalView({isPreviewMode: true})
    const view = screen.getByTestId('rubric-assessment-traditional-view')
    expect(view).toHaveAttribute('data-testid', 'rubric-assessment-traditional-view')
  })

  it('displays criterion descriptions', () => {
    renderTraditionalView()
    expect(screen.getByText('First Criterion')).toBeInTheDocument()
  })

  it('displays rating descriptions', () => {
    renderTraditionalView()
    expect(screen.getByText('Full Marks')).toBeInTheDocument()
    expect(screen.getByText('Partial Marks')).toBeInTheDocument()
  })

  it('handles assessment data updates', async () => {
    const user = userEvent.setup()

    renderTraditionalView({isFreeFormCriterionComments: true})

    const commentInput = screen.getByTestId('free-form-comment-area-criterion_1')
    await user.type(commentInput, 'Test comment')
    await user.tab() // Trigger onBlur to update assessment data

    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledWith(
      expect.objectContaining({
        criterionId: 'criterion_1',
        comments: 'Test comment',
      }),
    )
  })

  it(`comment blur does not clear rating for criterion where ratings' points are different`, async () => {
    renderTraditionalView()

    const commentInput = screen.getByTestId('comment-text-area-criterion_1')
    fireEvent.blur(commentInput)

    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledWith({
      ...defaultAssessmentData[0],
      ratingId: defaultAssessmentData[0].id,
    })
    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledTimes(1)
  })

  it(`comment blur does not clear rating for criterion where ratings' points are equal`, async () => {
    renderTraditionalView()

    const commentInput = screen.getByTestId('comment-text-area-criterion_2')
    fireEvent.blur(commentInput)

    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledWith({
      ...defaultAssessmentData[1],
      ratingId: defaultAssessmentData[1].id,
    })
    expect(defaultProps.onUpdateAssessmentData).toHaveBeenCalledTimes(1)
  })

  describe('AiUsageButton rendering', () => {
    it('renders AiUsageButton when isAiEvaluated is true', () => {
      renderTraditionalView({isAiEvaluated: true})
      expect(screen.getByTestId('ai-usage-button')).toBeInTheDocument()
    })

    it('does not render AiUsageButton when isAiEvaluated is false', () => {
      renderTraditionalView({isAiEvaluated: false})
      expect(screen.queryByTestId('ai-usage-button')).not.toBeInTheDocument()
    })

    it('does not render AiUsageButton when isAiEvaluated is not provided', () => {
      renderTraditionalView()
      expect(screen.queryByTestId('ai-usage-button')).not.toBeInTheDocument()
    })
  })
})

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
import {RubricSection} from '../RubricSection'
import type {RubricAssessment} from '../../../../types'

describe('RubricSection', () => {
  const mockRubricAssessment: RubricAssessment = {
    _id: 'rubric1',
    score: 85,
    assessmentRatings: [
      {
        _id: 'rating1',
        criterion: {
          _id: 'criterion1',
          description: 'Content Quality',
          longDescription: 'How well does the content address the topic?',
          points: 50,
        },
        description: 'Good work',
        points: 45,
        comments: 'Nice job on the analysis',
        commentsHtml: '<p>Nice job on the analysis</p>',
      },
      {
        _id: 'rating2',
        criterion: {
          _id: 'criterion2',
          description: 'Grammar',
          longDescription: null,
          points: 50,
        },
        description: 'Excellent',
        points: 40,
        comments: null,
        commentsHtml: null,
      },
    ],
  }

  it('renders rubric section with assessment ratings', () => {
    render(<RubricSection rubricAssessment={mockRubricAssessment} submissionId="sub1" />)

    expect(screen.getByTestId('rubric-section-sub1')).toBeInTheDocument()
    expect(screen.getByTestId('rubric-section-heading-sub1')).toHaveTextContent('Rubric')
  })

  it('displays criterion descriptions and points', () => {
    render(<RubricSection rubricAssessment={mockRubricAssessment} submissionId="sub1" />)

    expect(screen.getByTestId('rubric-criterion-description-criterion1')).toHaveTextContent(
      'Content Quality',
    )
    expect(screen.getByTestId('rubric-criterion-points-criterion1')).toHaveTextContent('45/50 pts')

    expect(screen.getByTestId('rubric-criterion-description-criterion2')).toHaveTextContent(
      'Grammar',
    )
    expect(screen.getByTestId('rubric-criterion-points-criterion2')).toHaveTextContent('40/50 pts')
  })

  it('displays rating comments when present', () => {
    render(<RubricSection rubricAssessment={mockRubricAssessment} submissionId="sub1" />)

    expect(screen.getByTestId('rubric-rating-comments-criterion1')).toHaveTextContent(
      'Nice job on the analysis',
    )
    expect(screen.queryByTestId('rubric-rating-comments-criterion2')).not.toBeInTheDocument()
  })

  it('renders nothing when rubricAssessment is null', () => {
    const {container} = render(<RubricSection rubricAssessment={null} submissionId="sub1" />)
    expect(container).toBeEmptyDOMElement()
  })

  it('renders nothing when assessmentRatings is empty', () => {
    const emptyAssessment: RubricAssessment = {
      _id: 'rubric1',
      score: 0,
      assessmentRatings: [],
    }

    const {container} = render(
      <RubricSection rubricAssessment={emptyAssessment} submissionId="sub1" />,
    )
    expect(container).toBeEmptyDOMElement()
  })

  it('handles null criterion gracefully', () => {
    const assessmentWithNullCriterion: RubricAssessment = {
      _id: 'rubric1',
      score: 85,
      assessmentRatings: [
        {
          _id: 'rating1',
          criterion: null,
          description: 'Good work',
          points: 45,
          comments: 'Nice job',
          commentsHtml: '<p>Nice job</p>',
        },
      ],
    }

    const {container} = render(
      <RubricSection rubricAssessment={assessmentWithNullCriterion} submissionId="sub1" />,
    )

    expect(screen.queryByTestId('rubric-criterion-description-criterion1')).not.toBeInTheDocument()
  })

  it('displays N/A when points are null', () => {
    const assessmentWithNullPoints: RubricAssessment = {
      _id: 'rubric1',
      score: null,
      assessmentRatings: [
        {
          _id: 'rating1',
          criterion: {
            _id: 'criterion1',
            description: 'Content Quality',
            longDescription: null,
            points: null,
          },
          description: 'Good work',
          points: null,
          comments: null,
          commentsHtml: null,
        },
      ],
    }

    render(<RubricSection rubricAssessment={assessmentWithNullPoints} submissionId="sub1" />)

    expect(screen.getByTestId('rubric-criterion-points-criterion1')).toHaveTextContent('N/A')
  })

  it('uses "Criterion" as fallback when description is null', () => {
    const assessmentWithNullDescription: RubricAssessment = {
      _id: 'rubric1',
      score: 85,
      assessmentRatings: [
        {
          _id: 'rating1',
          criterion: {
            _id: 'criterion1',
            description: null,
            longDescription: null,
            points: 50,
          },
          description: 'Good work',
          points: 45,
          comments: null,
          commentsHtml: null,
        },
      ],
    }

    render(<RubricSection rubricAssessment={assessmentWithNullDescription} submissionId="sub1" />)

    expect(screen.getByTestId('rubric-criterion-description-criterion1')).toHaveTextContent(
      'Criterion',
    )
  })
})

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
import {fireEvent, render} from '@testing-library/react'
import {RUBRIC_DATA, SELF_ASSESSMENT_DATA, TEACHER_ASSESSMENT_DATA} from './fixtures'
import {
  RubricAssessmentContainer,
  type RubricAssessmentContainerProps,
} from '../RubricAssessmentContainer'

describe('RubricAssessmentContainer Tests', () => {
  const renderComponent = (props?: Partial<RubricAssessmentContainerProps>) => {
    return render(
      <RubricAssessmentContainer
        criteria={RUBRIC_DATA.criteria}
        hidePoints={false}
        isFreeFormCriterionComments={false}
        isPeerReview={false}
        isPreviewMode={false}
        ratingOrder="descending"
        rubricAssessmentData={[]}
        rubricTitle="Rubric"
        viewModeOverride="horizontal"
        onDismiss={jest.fn()}
        onSubmit={jest.fn()}
        {...props}
      />,
    )
  }

  describe('Self Assessment tests', () => {
    const selfAssessment = {
      selfAssessment: SELF_ASSESSMENT_DATA,
      selfAssessmentDate: '2021-01-01T00:00:00Z',
      submissionUser: {avatarUrl: '', name: 'Test Student'},
    }

    it('should not display the self assessment toggle when there is no self assessment for the rubric', () => {
      const {queryByTestId} = renderComponent()
      expect(queryByTestId('self-assessment-toggle')).toBeNull()
    })

    it('should display the self assessment toggle when there is a self assessment for the rubric', () => {
      const {getByTestId} = renderComponent(selfAssessment)
      expect(getByTestId('self-assessment-toggle')).toBeInTheDocument()
    })

    it('should display the self assessment when the self assessment toggle is clicked', () => {
      const {getByTestId} = renderComponent(selfAssessment)
      fireEvent.click(getByTestId('self-assessment-toggle'))

      expect(getByTestId('rubric-rating-button-self-assessment-selected-3')).toBeInTheDocument()
      expect(getByTestId('rubric-rating-button-self-assessment-selected-1')).toBeInTheDocument()
      const firstDetailsDiv = getByTestId('rating-details-3')
      expect(firstDetailsDiv).toHaveTextContent('Rating 3')
      expect(firstDetailsDiv).toHaveTextContent('great work')
      expect(getByTestId('self-assessment-comment-3')).toBeInTheDocument()

      const secondDetailsDiv = getByTestId('rating-details-10')
      expect(secondDetailsDiv).toHaveTextContent('Rating 10')
      expect(secondDetailsDiv).toHaveTextContent('amazing work')
    })

    it('should display a mix of teacher and self assessment when the self assessment toggle is clicked', () => {
      const {getByTestId} = renderComponent({
        ...selfAssessment,
        rubricAssessmentData: TEACHER_ASSESSMENT_DATA,
      })
      fireEvent.click(getByTestId('self-assessment-toggle'))

      expect(getByTestId('rubric-rating-button-self-assessment-selected-3')).toBeInTheDocument()
      expect(getByTestId('rubric-rating-button-self-assessment-selected-1')).toBeInTheDocument()
      const ratingDiv = getByTestId('rating-button-2-2')
      expect(
        ratingDiv.querySelector('div[data-testid="rubric-rating-button-selected"]'),
      ).toBeInTheDocument()

      const firstDetailsDiv = getByTestId('rating-details-2')
      expect(firstDetailsDiv).toHaveTextContent('Rating 2')
      expect(firstDetailsDiv).toHaveTextContent('mid')
      expect(getByTestId('self-assessment-comment-3')).toBeInTheDocument()

      const secondDetailsDiv = getByTestId('rating-details-10')
      expect(secondDetailsDiv).toHaveTextContent('Rating 10')
      expect(secondDetailsDiv).toHaveTextContent('amazing work')
    })
  })
})

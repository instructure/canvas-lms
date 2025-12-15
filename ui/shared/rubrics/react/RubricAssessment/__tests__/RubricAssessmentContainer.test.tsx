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
import {queryClient} from '@canvas/query'
import {OUTCOME_DATA, RUBRIC_DATA, SELF_ASSESSMENT_DATA, TEACHER_ASSESSMENT_DATA} from './fixtures'
import {RubricCriterion} from '../../types/rubric'

import {
  RubricAssessmentContainer,
  type RubricAssessmentContainerProps,
} from '../RubricAssessmentContainer'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'

describe('RubricAssessmentContainer Tests', () => {
  const renderComponent = (props?: Partial<RubricAssessmentContainerProps>) => {
    return render(
      <MockedQueryProvider>
        <RubricAssessmentContainer
          buttonDisplay="level"
          criteria={RUBRIC_DATA.criteria}
          currentUserId="1"
          hidePoints={false}
          isFreeFormCriterionComments={false}
          isPeerReview={false}
          isPreviewMode={false}
          ratingOrder="descending"
          rubricAssessmentData={[]}
          rubricTitle="Rubric"
          viewModeOverride="horizontal"
          onDismiss={vi.fn()}
          onSubmit={vi.fn()}
          {...props}
        />
      </MockedQueryProvider>,
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

  describe('Outcome tag tests', () => {
    it('displays outcome tag with clickable tag details to open popover', () => {
      queryClient.setQueryData(['rubric_outcome_', '1'], OUTCOME_DATA)
      const {friendlyCalculationMethod, exampleText} = new CalculationMethodContent({
        calculation_method: OUTCOME_DATA.calculationMethod,
        calculation_int: OUTCOME_DATA.calculationInt,
        is_individual_outcome: true,
        mastery_points: OUTCOME_DATA.masteryPoints,
      }).present()
      const outcomeCriteria: RubricCriterion = {
        ...RUBRIC_DATA.criteria[0],
        outcome: {
          displayName: 'Test Outcome',
          title: 'Outcome 1',
        },
        learningOutcomeId: '1',
      }

      const criteria = [outcomeCriteria]

      const {getByTestId} = renderComponent({criteria})

      const outcomeTag = getByTestId('rubric-criteria-row-outcome-tag')
      expect(outcomeTag).toBeInTheDocument()

      fireEvent.click(outcomeTag)

      expect(getByTestId('outcome-popover-display')).toBeInTheDocument()
      expect(getByTestId('outcome-popover-display-name')).toHaveTextContent(
        OUTCOME_DATA.displayName,
      )
      expect(getByTestId('outcome-popover-title')).toHaveTextContent(OUTCOME_DATA.title)
      expect(getByTestId('outcome-popover-display-content-description')).toHaveTextContent(
        OUTCOME_DATA.description,
      )
      expect(getByTestId('outcome-popover-display-content-calculation-method')).toHaveTextContent(
        friendlyCalculationMethod,
      )
      expect(getByTestId('outcome-popover-display-content-example')).toHaveTextContent(exampleText)
    })

    it('displays outcome tag with title as display name if display name is empty', () => {
      queryClient.setQueryData(['rubric_outcome_', '1'], {...OUTCOME_DATA, displayName: ''})
      const outcomeCriteria: RubricCriterion = {
        ...RUBRIC_DATA.criteria[0],
        outcome: {
          displayName: '',
          title: 'Outcome 1',
        },
        learningOutcomeId: '1',
      }

      const criteria = [outcomeCriteria]

      const {getByTestId, queryByTestId} = renderComponent({criteria})

      const outcomeTag = getByTestId('rubric-criteria-row-outcome-tag')
      expect(outcomeTag).toBeInTheDocument()

      fireEvent.click(outcomeTag)

      expect(getByTestId('outcome-popover-display')).toBeInTheDocument()
      expect(getByTestId('outcome-popover-display-name')).toHaveTextContent(OUTCOME_DATA.title)
      expect(queryByTestId('outcome-popover-title')).not.toBeInTheDocument()
    })

    it('displays outcome tag without calculation method and example if not present', () => {
      queryClient.setQueryData(['rubric_outcome_', '1'], {
        ...OUTCOME_DATA,
        calculationMethod: null,
        calculationInt: null,
      })
      const outcomeCriteria: RubricCriterion = {
        ...RUBRIC_DATA.criteria[0],
        outcome: {
          displayName: 'Test Outcome',
          title: 'Outcome 1',
        },
        learningOutcomeId: '1',
      }

      const criteria = [outcomeCriteria]

      const {getByTestId, queryByTestId} = renderComponent({criteria})

      const outcomeTag = getByTestId('rubric-criteria-row-outcome-tag')
      expect(outcomeTag).toBeInTheDocument()

      fireEvent.click(outcomeTag)

      expect(getByTestId('outcome-popover-display')).toBeInTheDocument()
      expect(getByTestId('outcome-popover-display-name')).toHaveTextContent(
        OUTCOME_DATA.displayName,
      )
      expect(getByTestId('outcome-popover-title')).toHaveTextContent(OUTCOME_DATA.title)
      expect(getByTestId('outcome-popover-display-content-description')).toHaveTextContent(
        OUTCOME_DATA.description,
      )
      expect(
        queryByTestId('outcome-popover-display-content-calculation-method'),
      ).not.toBeInTheDocument()
      expect(queryByTestId('outcome-popover-display-content-example')).not.toBeInTheDocument()
    })
  })

  describe('Assessment Status tests', () => {
    it('should show the "incomplete" status when a rubric has not yet been completed', () => {
      const {getByTestId} = renderComponent()

      expect(getByTestId('rubric-assessment-status-pill')).toHaveTextContent('Incomplete')
    })

    it('should show the "complete" status when a rubric has been completed', () => {
      const {getByTestId} = renderComponent({
        rubricAssessmentData: [
          {
            id: '_1',
            points: 4,
            comments: 'Great Job!',
            criterionId: '1',
            description: 'Rating 10',
          },
          {
            id: '_2',
            points: 10,
            comments: 'Great Job!',
            criterionId: '2',
            description: 'Rating 10',
          },
        ],
      })

      expect(getByTestId('rubric-assessment-status-pill')).toHaveTextContent('Complete')
    })

    it('should show as incomplete if not all criteria are filled out', () => {
      const {getByTestId} = renderComponent({
        rubricAssessmentData: [
          {
            id: '_1',
            points: 4,
            comments: 'Great Job!',
            criterionId: '1',
            description: 'Rating 10',
          },
        ],
      })

      expect(getByTestId('rubric-assessment-status-pill')).toHaveTextContent('Incomplete')
    })

    it('should show as incomplete if the rubric only has comments but points are not hidden', () => {
      const {getByTestId} = renderComponent({
        isFreeFormCriterionComments: true,
        rubricAssessmentData: [
          {
            id: '_1',
            points: undefined,
            comments: 'Great Job!',
            criterionId: '1',
            description: 'Rating 10',
          },
          {
            id: '_2',
            points: undefined,
            comments: 'Great Job!',
            criterionId: '2',
            description: 'Rating 10',
          },
        ],
      })

      expect(getByTestId('rubric-assessment-status-pill')).toHaveTextContent('Incomplete')
    })

    it('should show as complete if the rubric is free form and points are hidden with only comments', () => {
      const {getByTestId} = renderComponent({
        isFreeFormCriterionComments: true,
        hidePoints: true,
        rubricAssessmentData: [
          {
            id: '_1',
            points: undefined,
            comments: 'Great Job!',
            criterionId: '1',
            description: 'Rating 10',
          },
          {
            id: '_2',
            points: undefined,
            comments: 'Great Job!',
            criterionId: '2',
            description: 'Rating 10',
          },
        ],
      })

      expect(getByTestId('rubric-assessment-status-pill')).toHaveTextContent('Complete')
    })
  })
})

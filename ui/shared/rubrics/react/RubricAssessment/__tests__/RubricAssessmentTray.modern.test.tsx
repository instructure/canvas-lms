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
import {RubricAssessmentTray, type RubricAssessmentTrayProps} from '../RubricAssessmentTray'
import {RUBRIC_DATA} from './fixtures'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('RubricAssessmentTray Modern View Tests', () => {
  beforeEach(() => {
    fakeENV.setup({
      current_user_id: '1',
    })
    queryClient.setQueryData(['_1_eg_rubric_view_mode'], 'traditional')
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  const renderComponent = (props?: Partial<RubricAssessmentTrayProps>) => {
    return render(
      <MockedQueryProvider>
        <RubricAssessmentTray
          currentUserId={'1'}
          isOpen={true}
          isPreviewMode={false}
          rubric={RUBRIC_DATA}
          rubricAssessmentData={[]}
          onDismiss={vi.fn()}
          onSubmit={vi.fn()}
          {...props}
        />
      </MockedQueryProvider>,
    )
  }

  const renderFreeformComponent = (props?: Partial<RubricAssessmentTrayProps>) => {
    const freeformRubric = {...RUBRIC_DATA, freeFormCriterionComments: true}
    return renderComponent({rubric: freeformRubric, ...props})
  }

  const getModernSelectedDiv = (element: HTMLElement) => {
    return element.querySelector('div[data-testid="rubric-rating-button-selected"]')
  }

  const renderComponentModern = (
    viewMode: string,
    isPeerReview = false,
    freeFormCriterionComments = false,
    props?: Partial<RubricAssessmentTrayProps>,
  ) => {
    queryClient.setQueryData(['_1_eg_rubric_view_mode'], viewMode)
    return freeFormCriterionComments
      ? renderFreeformComponent({isPeerReview, ...props})
      : renderComponent({isPeerReview, ...props})
  }

  describe('Horizontal Display tests', () => {
    it('should select a rating when the rating is clicked', () => {
      const {getByTestId, queryByTestId} = renderComponentModern('Horizontal')

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')

      const ratingDiv = getByTestId('rating-button-4-0')
      expect(getModernSelectedDiv(ratingDiv)).toBeNull()
      expect(queryByTestId('rating-details-4')).toBeNull()
      const button = ratingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(button)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getModernSelectedDiv(ratingDiv)).toBeInTheDocument()
      const detailsDiv = getByTestId('rating-details-4')
      expect(detailsDiv).toHaveTextContent(RUBRIC_DATA.criteria[0].ratings[0].description)
      expect(detailsDiv).toHaveTextContent(RUBRIC_DATA.criteria[0].ratings[0].longDescription)
    })

    it('should reselect a rating for the same criterion when another rating is clicked', () => {
      const {getByTestId} = renderComponentModern('Horizontal')

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')

      const oldRatingDiv = getByTestId('rating-button-4-0')
      expect(getModernSelectedDiv(oldRatingDiv)).toBeNull()
      const oldRatingButton = oldRatingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(oldRatingButton)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getModernSelectedDiv(oldRatingDiv)).toBeInTheDocument()

      const newRatingDiv = getByTestId('rating-button-3-1')
      expect(getModernSelectedDiv(newRatingDiv)).toBeNull()
      const newRatingButton = newRatingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(newRatingButton)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('3 pts')
      expect(getModernSelectedDiv(newRatingDiv)).toBeInTheDocument()
      expect(getModernSelectedDiv(oldRatingDiv)).toBeNull()
    })

    it('should select multiple ratings across multiple criteria', () => {
      const {getByTestId} = renderComponentModern('Horizontal')

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')

      const oldRatingDiv = getByTestId('rating-button-4-0')
      expect(getModernSelectedDiv(oldRatingDiv)).toBeNull()
      const oldRatingButton = oldRatingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(oldRatingButton)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getModernSelectedDiv(oldRatingDiv)).toBeInTheDocument()

      const newRatingDiv = getByTestId('rating-button-10-0')
      expect(getModernSelectedDiv(newRatingDiv)).toBeNull()
      const newRatingButton = newRatingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(newRatingButton)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('14 pts')
      expect(getModernSelectedDiv(newRatingDiv)).toBeInTheDocument()
      expect(getModernSelectedDiv(oldRatingDiv)).toBeInTheDocument()
    })

    it('should select a rating matching user entered points', () => {
      const {getByTestId} = renderComponentModern('Horizontal')
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const input = getByTestId('criterion-score-2') as HTMLInputElement
      fireEvent.change(input, {target: {value: '10'}})
      fireEvent.blur(input)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('10 pts')
      const ratingDiv = getByTestId('rating-button-10-0')
      expect(getModernSelectedDiv(ratingDiv)).toBeInTheDocument()
    })

    it('should not select a rating when user entered points do not match a rating points value', () => {
      const {getByTestId} = renderComponentModern('Horizontal')
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const input = getByTestId('criterion-score-2') as HTMLInputElement
      fireEvent.change(input, {target: {value: '20'}})
      fireEvent.blur(input)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('20 pts')
      const ratingDiv1 = getByTestId('rating-button-10-0')
      const ratingDiv2 = getByTestId('rating-button-00-1')
      expect(getModernSelectedDiv(ratingDiv1)).not.toBeInTheDocument()
      expect(getModernSelectedDiv(ratingDiv2)).not.toBeInTheDocument()
    })

    it('should select a rating matching user entered points for ranged rubrics', () => {
      const {getByTestId} = renderComponentModern('Horizontal')
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const input = getByTestId('criterion-score-1') as HTMLInputElement
      fireEvent.change(input, {target: {value: '2.5'}})
      fireEvent.blur(input)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('2.5 pts')
      const ratingDiv = getByTestId('rating-button-3-1')
      expect(getModernSelectedDiv(ratingDiv)).toBeInTheDocument()
    })

    describe('Free Form Comments', () => {
      it('should not render the rating buttons when free form comments are enabled', () => {
        const {queryByTestId} = renderComponentModern('Horizontal', false, true, {})

        expect(queryByTestId('rubric-assessment-horizontal-display')).not.toBeInTheDocument()
      })

      it('should render the comment library dropdown if saved comments exist for that criterion', () => {
        const {getByTestId, queryByTestId, queryByRole} = renderComponentModern(
          'Horizontal',
          false,
          true,
          {rubricSavedComments: {1: ['comment 1']}},
        )
        const commentLibrary = getByTestId('comment-library-1')
        fireEvent.click(commentLibrary)

        expect(queryByRole('option', {name: 'comment 1'})).toBeInTheDocument()
        expect(queryByTestId('comment-library-2')).not.toBeInTheDocument()
      })

      it('should not render the comment library when in preview', () => {
        const {queryByTestId} = renderComponentModern('Horizontal', false, true, {
          rubricSavedComments: {1: ['comment 1']},
          isPreviewMode: true,
        })

        expect(queryByTestId('comment-library-1')).not.toBeInTheDocument()
      })

      it('should not render the comment library when in peer review mode', () => {
        const {queryByTestId} = renderComponentModern('Horizontal', true, true, {
          rubricSavedComments: {1: ['comment 1']},
        })

        expect(queryByTestId('comment-library-1')).not.toBeInTheDocument()
      })

      it('should add a saved comment to the comment text area when a comment is selected from the comment library', () => {
        const {getByTestId, queryByRole} = renderComponentModern('Horizontal', false, true, {
          rubricSavedComments: {1: ['comment 1']},
        })
        const commentLibrary = getByTestId('comment-library-1')
        fireEvent.click(commentLibrary)

        const commentOption = queryByRole('option', {name: 'comment 1'}) as HTMLElement
        fireEvent.click(commentOption)

        expect(getByTestId('free-form-comment-area-1')).toHaveValue('comment 1')
      })

      it('should render the save comment for later checkbox for each criterion', () => {
        const {getByTestId} = renderComponentModern('Horizontal', false, true, {
          rubricSavedComments: {1: ['comment 1']},
        })

        expect(getByTestId('save-comment-checkbox-1')).toBeInTheDocument()
        expect(getByTestId('save-comment-checkbox-2')).toBeInTheDocument()
      })

      it('should not render the save comment for later checkbox when in preview', () => {
        const {queryByTestId} = renderComponentModern('Horizontal', false, true, {
          rubricSavedComments: {1: ['comment 1']},
          isPreviewMode: true,
        })

        expect(queryByTestId('save-comment-checkbox-1')).not.toBeInTheDocument()
        expect(queryByTestId('save-comment-checkbox-2')).not.toBeInTheDocument()
      })

      it('should not render the save comment for later checkbox when in peer review mode', () => {
        const {queryByTestId} = renderComponentModern('Horizontal', true, true, {
          rubricSavedComments: {1: ['comment 1']},
        })

        expect(queryByTestId('save-comment-checkbox-1')).not.toBeInTheDocument()
        expect(queryByTestId('save-comment-checkbox-2')).not.toBeInTheDocument()
      })
    })

    it('should not render score input if criterion is ignoreForScoring', () => {
      const updatedRubric = {
        ...RUBRIC_DATA,
        criteria: RUBRIC_DATA.criteria.map(criterion =>
          criterion.id === '2' ? {...criterion, ignoreForScoring: true} : criterion,
        ),
      }

      const {queryByTestId} = renderComponentModern('Horizontal', false, false, {
        rubric: updatedRubric,
      })
      expect(queryByTestId('criterion-score-1')).toBeInTheDocument()
      expect(queryByTestId('criterion-score-2')).not.toBeInTheDocument()
    })
  })

  describe('Vertical Display tests', () => {
    it('should select a rating when the rating is clicked', () => {
      const {getByTestId, queryByTestId} = renderComponentModern('Vertical')

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')

      const ratingDiv = getByTestId('rating-button-4-0')
      expect(getModernSelectedDiv(ratingDiv)).toBeNull()
      expect(queryByTestId('rating-details-4')).toBeNull()
      const button = ratingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(button)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getModernSelectedDiv(ratingDiv)).toBeInTheDocument()
      const detailsDiv = getByTestId('rating-details-4')
      expect(detailsDiv).toHaveTextContent(RUBRIC_DATA.criteria[0].ratings[0].description)
      expect(detailsDiv).toHaveTextContent(RUBRIC_DATA.criteria[0].ratings[0].longDescription)
    })

    it('should reselect a rating for the same criterion when another rating is clicked', () => {
      const {getByTestId} = renderComponentModern('Vertical')

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')

      const oldRatingDiv = getByTestId('rating-button-4-0')
      expect(getModernSelectedDiv(oldRatingDiv)).toBeNull()
      const oldRatingButton = oldRatingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(oldRatingButton)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getModernSelectedDiv(oldRatingDiv)).toBeInTheDocument()

      const newRatingDiv = getByTestId('rating-button-3-1')
      expect(getModernSelectedDiv(newRatingDiv)).toBeNull()
      const newRatingButton = newRatingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(newRatingButton)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('3 pts')
      expect(getModernSelectedDiv(newRatingDiv)).toBeInTheDocument()
      expect(getModernSelectedDiv(oldRatingDiv)).toBeNull()
    })

    it('should select multiple ratings across multiple criteria', () => {
      const {getByTestId} = renderComponentModern('Vertical')

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')

      const oldRatingDiv = getByTestId('rating-button-4-0')
      expect(getModernSelectedDiv(oldRatingDiv)).toBeNull()
      const oldRatingButton = oldRatingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(oldRatingButton)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getModernSelectedDiv(oldRatingDiv)).toBeInTheDocument()

      const newRatingDiv = getByTestId('rating-button-10-0')
      expect(getModernSelectedDiv(newRatingDiv)).toBeNull()
      const newRatingButton = newRatingDiv.querySelector('button') as HTMLButtonElement
      fireEvent.click(newRatingButton)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('14 pts')
      expect(getModernSelectedDiv(newRatingDiv)).toBeInTheDocument()
      expect(getModernSelectedDiv(oldRatingDiv)).toBeInTheDocument()
    })

    it('should not render Vertical option when free form comments are enabled', () => {
      const {getByTestId, queryByRole} = renderFreeformComponent()
      const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

      fireEvent.click(viewModeSelect)

      expect(queryByRole('option', {name: 'Vertical'}) as HTMLElement).not.toBeInTheDocument()
    })

    it('should not render score input if criterion is ignoreForScoring', () => {
      const updatedRubric = {
        ...RUBRIC_DATA,
        criteria: RUBRIC_DATA.criteria.map(criterion =>
          criterion.id === '2' ? {...criterion, ignoreForScoring: true} : criterion,
        ),
      }

      const {queryByTestId} = renderComponentModern('Vertical', false, false, {
        rubric: updatedRubric,
      })
      expect(queryByTestId('criterion-score-1')).toBeInTheDocument()
      expect(queryByTestId('criterion-score-2')).not.toBeInTheDocument()
    })
  })
})

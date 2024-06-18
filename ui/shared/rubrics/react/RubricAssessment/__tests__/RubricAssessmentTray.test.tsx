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

describe('RubricAssessmentTray Tests', () => {
  const renderComponent = (props?: Partial<RubricAssessmentTrayProps>) => {
    return render(
      <RubricAssessmentTray
        isOpen={true}
        isPreviewMode={false}
        rubric={RUBRIC_DATA}
        rubricAssessmentData={[]}
        onDismiss={jest.fn()}
        onSubmit={jest.fn()}
        {...props}
      />
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
    props?: Partial<RubricAssessmentTrayProps>
  ) => {
    const component = freeFormCriterionComments
      ? renderFreeformComponent({isPeerReview, ...props})
      : renderComponent({isPeerReview, ...props})
    const {getByTestId, queryByRole} = component
    const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

    fireEvent.click(viewModeSelect)
    const roleOption = queryByRole('option', {name: viewMode}) as HTMLElement
    fireEvent.click(roleOption)

    return component
  }

  describe('View Mode Select tests', () => {
    it('should render the traditional view option by default', () => {
      const {getByTestId} = renderComponent()
      const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

      expect(viewModeSelect.value).toBe('Traditional')
      expect(getByTestId('rubric-assessment-traditional-view')).toBeInTheDocument()
      expect(getByTestId('rubric-assessment-header')).toHaveTextContent('Rubric')
      expect(getByTestId('rubric-assessment-footer')).toBeInTheDocument()
    })

    it('should render the vertical view option by default if a criterion has greater than 5 ratings', () => {
      const rubric = {...RUBRIC_DATA}
      rubric.criteria = [...rubric.criteria]
      const ratings = [...rubric.criteria[0].ratings]
      ratings.push({description: '6', points: 6, id: '6', longDescription: '6th rating'})
      rubric.criteria[0] = {...rubric.criteria[0], ratings}
      const {getByTestId, queryAllByTestId} = renderComponent({rubric})
      const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

      expect(viewModeSelect.value).toBe('Vertical')
      expect(queryAllByTestId('rubric-assessment-vertical-display')).toHaveLength(2)
    })

    it('should switch to the horizontal view when the horizontal option is selected', () => {
      const {getByTestId, queryAllByTestId, queryByRole} = renderComponent()
      const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

      fireEvent.click(viewModeSelect)
      const roleOption = queryByRole('option', {name: 'Horizontal'}) as HTMLElement
      fireEvent.click(roleOption)

      expect(viewModeSelect.value).toBe('Horizontal')
      expect(queryAllByTestId('rubric-assessment-horizontal-display')).toHaveLength(2)
    })

    it('should switch to the vertical view when the vertical option is selected', async () => {
      const {getByTestId, queryAllByTestId, queryByRole} = renderComponent()
      const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

      fireEvent.click(viewModeSelect)
      const roleOption = queryByRole('option', {name: 'Vertical'}) as HTMLElement
      fireEvent.click(roleOption)

      expect(viewModeSelect.value).toBe('Vertical')
      expect(queryAllByTestId('rubric-assessment-vertical-display')).toHaveLength(2)
    })
  })

  describe('Traditional View tests', () => {
    it('should select a rating when the rating is clicked', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const rating = getByTestId('traditional-criterion-1-ratings-0') as HTMLButtonElement

      fireEvent.click(rating)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')

      expect(getByTestId('traditional-criterion-1-ratings-0-selected')).toBeInTheDocument()
    })

    it('should reselect a rating for the same criterion when another rating is clicked', () => {
      const {getByTestId, queryByTestId} = renderComponent()
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const rating = getByTestId('traditional-criterion-1-ratings-0') as HTMLButtonElement
      fireEvent.click(rating)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getByTestId('traditional-criterion-1-ratings-0-selected')).toBeInTheDocument()

      const newRating = getByTestId('traditional-criterion-1-ratings-1') as HTMLButtonElement
      fireEvent.click(newRating)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('3 pts')
      expect(queryByTestId('traditional-criterion-1-ratings-0-selected')).toBeNull()
      expect(getByTestId('traditional-criterion-1-ratings-1-selected')).toBeInTheDocument()
    })

    it('should select multiple ratings across multiple criteria', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const rating = getByTestId('traditional-criterion-1-ratings-0') as HTMLButtonElement
      fireEvent.click(rating)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getByTestId('traditional-criterion-1-ratings-0-selected')).toBeInTheDocument()

      const newRating = getByTestId('traditional-criterion-2-ratings-0') as HTMLButtonElement
      fireEvent.click(newRating)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('14 pts')
      expect(getByTestId('traditional-criterion-1-ratings-0-selected')).toBeInTheDocument()
      expect(getByTestId('traditional-criterion-2-ratings-0-selected')).toBeInTheDocument()
    })

    it('should select a rating matching user entered points', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const input = getByTestId('criterion-score-2') as HTMLInputElement
      fireEvent.change(input, {target: {value: '10'}})
      fireEvent.blur(input)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('10 pts')
      expect(getByTestId('traditional-criterion-2-ratings-0-selected')).toBeInTheDocument()
    })

    it('should not select a rating when user entered points do not match a rating points value', () => {
      const {getByTestId, queryByTestId} = renderComponent()
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const input = getByTestId('criterion-score-2') as HTMLInputElement
      fireEvent.change(input, {target: {value: '20'}})
      fireEvent.blur(input)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('20 pts')
      expect(queryByTestId('traditional-criterion-2-ratings-0-selected')).not.toBeInTheDocument()
      expect(queryByTestId('traditional-criterion-2-ratings-1-selected')).not.toBeInTheDocument()
    })

    it('should select a rating matching user entered points for ranged rubrics', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      const input = getByTestId('criterion-score-1') as HTMLInputElement
      fireEvent.change(input, {target: {value: '2.5'}})
      fireEvent.blur(input)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('2.5 pts')
      expect(getByTestId('traditional-criterion-1-ratings-1-selected')).toBeInTheDocument()
    })

    it('should display the comments section', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('comment-text-area-1')).toBeInTheDocument()
    })

    describe('Free Form Comments', () => {
      it('should render comment text box instead of the rating selection within the rubric grid', () => {
        const {getByTestId, queryByTestId} = renderFreeformComponent({})

        expect(getByTestId('free-form-comment-area-1')).toBeInTheDocument()
        expect(queryByTestId('traditional-criterion-1-ratings-0')).not.toBeInTheDocument()
      })

      it('should render the comment library dropdown if saved comments exist for that criterion', () => {
        const {getByTestId, queryByTestId, queryByRole} = renderFreeformComponent({
          rubricSavedComments: {1: ['comment 1']},
        })
        const commentLibrary = getByTestId('comment-library-1')
        fireEvent.click(commentLibrary)

        expect(queryByRole('option', {name: 'comment 1'})).toBeInTheDocument()
        expect(queryByTestId('comment-library-2')).not.toBeInTheDocument()
      })

      it('should not render the comment library when in preview', () => {
        const {queryByTestId} = renderFreeformComponent({isPreviewMode: true})

        expect(queryByTestId('comment-library-1')).not.toBeInTheDocument()
      })

      it('should not render the comment library when in peer review mode', () => {
        const {queryByTestId} = renderFreeformComponent({isPeerReview: true})

        expect(queryByTestId('comment-library-1')).not.toBeInTheDocument()
      })

      it('should add a saved comment to the comment text area when a comment is selected from the comment library', () => {
        const {getByTestId, queryByRole} = renderFreeformComponent({
          rubricSavedComments: {1: ['comment 1']},
        })
        const commentLibrary = getByTestId('comment-library-1')
        fireEvent.click(commentLibrary)

        const commentOption = queryByRole('option', {name: 'comment 1'}) as HTMLElement
        fireEvent.click(commentOption)

        expect(getByTestId('free-form-comment-area-1')).toHaveValue('comment 1')
      })

      it('should render the save comment for later checkbox for each criterion', () => {
        const {getByTestId} = renderFreeformComponent({})

        expect(getByTestId('save-comment-checkbox-1')).toBeInTheDocument()
        expect(getByTestId('save-comment-checkbox-2')).toBeInTheDocument()
      })

      it('should not render the save comment for later checkbox when in preview', () => {
        const {queryByTestId} = renderFreeformComponent({isPreviewMode: true})

        expect(queryByTestId('save-comment-checkbox-1')).not.toBeInTheDocument()
        expect(queryByTestId('save-comment-checkbox-2')).not.toBeInTheDocument()
      })

      it('should not render the save comment for later checkbox when in peer review mode', () => {
        const {queryByTestId} = renderFreeformComponent({isPeerReview: true})

        expect(queryByTestId('save-comment-checkbox-1')).not.toBeInTheDocument()
        expect(queryByTestId('save-comment-checkbox-2')).not.toBeInTheDocument()
      })

      it('should render point inputs within the points column of the rubric grid', () => {
        const {getByTestId} = renderFreeformComponent({})

        expect(getByTestId('criterion-score-1')).toBeInTheDocument()
      })

      it('should not render the comment icon button in the points column', () => {
        const {queryByTestId} = renderFreeformComponent({})

        expect(queryByTestId('rubric-comment-button-1')).not.toBeInTheDocument()
      })

      it('should update the instructor score when a point input is changed within the points column', () => {
        const {getByTestId} = renderFreeformComponent({})
        const input = getByTestId('criterion-score-1') as HTMLInputElement
        fireEvent.change(input, {target: {value: '4'}})
        fireEvent.blur(input)

        expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')

        const input2 = getByTestId('criterion-score-2') as HTMLInputElement
        fireEvent.change(input2, {target: {value: '5'}})
        fireEvent.blur(input2)

        expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('9 pts')
      })
    })
  })

  describe('Modern View tests', () => {
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
        const {getByTestId, queryByTestId} = renderComponentModern('Horizontal')
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
            {rubricSavedComments: {1: ['comment 1']}}
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
        const viewModeSelect = getByTestId(
          'rubric-assessment-view-mode-select'
        ) as HTMLSelectElement

        fireEvent.click(viewModeSelect)

        expect(queryByRole('option', {name: 'Vertical'}) as HTMLElement).not.toBeInTheDocument()
      })
    })

    it('should keep the selected rating when switching between view modes', () => {
      const {getByTestId, queryByTestId, queryByRole, queryAllByTestId} = renderComponent()
      const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

      const rating = getByTestId('traditional-criterion-1-ratings-0') as HTMLButtonElement
      fireEvent.click(rating)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(getByTestId('traditional-criterion-1-ratings-0-selected')).toBeInTheDocument()

      fireEvent.click(viewModeSelect)
      const roleOption = queryByRole('option', {name: 'Horizontal'}) as HTMLElement
      fireEvent.click(roleOption)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(queryAllByTestId('rubric-assessment-horizontal-display')).toHaveLength(2)
      const horizontalRatingDiv = queryByTestId('rating-button-4-0') as HTMLElement
      expect(getModernSelectedDiv(horizontalRatingDiv)).toBeInTheDocument()

      fireEvent.click(viewModeSelect)
      const verticalRoleOption = queryByRole('option', {name: 'Vertical'}) as HTMLElement
      fireEvent.click(verticalRoleOption)

      expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('4 pts')
      expect(queryAllByTestId('rubric-assessment-vertical-display')).toHaveLength(2)
      const verticalRatingDiv = queryByTestId('rating-button-4-0') as HTMLElement
      expect(getModernSelectedDiv(verticalRatingDiv)).toBeInTheDocument()
    })
  })

  describe('Peer Review tests', () => {
    const rubricAssessors = [
      {id: '1', name: 'Teacher'},
      {id: '2', name: 'Peer Reviewer'},
    ]

    const renderPeerReviewComponent = () => {
      return renderComponent({isPeerReview: true, rubricAssessors, rubricAssessmentId: '2'})
    }

    it('should display the peer review text when in peer review mode', () => {
      const {getByTestId} = renderPeerReviewComponent()
      expect(getByTestId('rubric-assessment-header')).toHaveTextContent('Peer Review')
    })

    it('should render the peer review assessment dropdown', () => {
      const {getByTestId, queryAllByRole} = renderPeerReviewComponent()
      const assessorSelect = getByTestId('rubric-assessment-accessor-select') as HTMLSelectElement
      expect(assessorSelect).toBeInTheDocument()
      expect(assessorSelect.value).toBe('Peer Reviewer')

      fireEvent.click(assessorSelect)
      const assessors = queryAllByRole('option') as HTMLElement[]
      expect(assessors.length).toBe(2)
      expect(assessors[0].innerHTML).toBe('Teacher')
      expect(assessors[1].innerHTML).toBe('Peer Reviewer')
    })
  })

  describe('Preview Mode tests', () => {
    it('should not render footer section when in peer review mode', () => {
      const {queryByTestId} = renderComponent({isPreviewMode: true})
      expect(queryByTestId('rubric-assessment-footer')).toBeNull()
    })

    describe('Traditional View tests', () => {
      it('should not allow users to select ratings when in preview mode', () => {
        const {getByTestId} = renderComponent({isPreviewMode: true})
        const rating = getByTestId('traditional-criterion-1-ratings-0') as HTMLButtonElement
        fireEvent.click(rating)

        expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      })
    })

    describe('Modern View tests', () => {
      it('should not allow users to select ratings when in preview mode', () => {
        const {getByTestId, queryByTestId, queryByRole} = renderComponent({isPreviewMode: true})

        const viewModeSelect = getByTestId(
          'rubric-assessment-view-mode-select'
        ) as HTMLSelectElement

        fireEvent.click(viewModeSelect)
        const roleOption = queryByRole('option', {name: 'Horizontal'}) as HTMLElement
        fireEvent.click(roleOption)

        expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')

        const ratingDiv = getByTestId('rating-button-4-0')
        expect(getModernSelectedDiv(ratingDiv)).toBeNull()
        expect(queryByTestId('rating-details-4')).toBeNull()
        const button = ratingDiv.querySelector('button') as HTMLButtonElement
        fireEvent.click(button)

        expect(getByTestId('rubric-assessment-instructor-score')).toHaveTextContent('0 pts')
      })
    })
  })

  describe('hidePoints tests', () => {
    it('should not display points when hidePoints is true', () => {
      const {getByTestId, queryByTestId} = renderComponent({hidePoints: true})
      expect(queryByTestId('rubric-assessment-instructor-score')).toBeNull()
      expect(getByTestId('traditional-criterion-1-ratings-0-points')).toHaveTextContent('')
    })

    it('should display points when hidePoints is false', () => {
      const {getByTestId} = renderComponent({hidePoints: false})
      expect(getByTestId('rubric-assessment-instructor-score')).toBeInTheDocument()
      expect(getByTestId('traditional-criterion-1-ratings-0-points')).toHaveTextContent('4 pts')
    })

    it('should not display points when hidePoints is true in modern view', () => {
      const {queryByTestId} = renderComponentModern('Vertical', false, false, {hidePoints: true})
      expect(queryByTestId('modern-view-out-of-points')).toBeNull()
    })

    it('should display points when hidePoints is false in modern view', () => {
      const {queryAllByTestId} = renderComponentModern('Vertical', false, false, {
        hidePoints: false,
      })
      expect(queryAllByTestId('modern-view-out-of-points')).toHaveLength(2)
    })
  })
})

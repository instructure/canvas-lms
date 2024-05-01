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
        {...props}
      />
    )
  }

  const getModernSelectedDiv = (element: HTMLElement) => {
    return element.querySelector('div[data-testid="rubric-rating-button-selected"]')
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

    it('should open the comments tray when the comments icon is clicked', () => {
      const {getByTestId, queryByTestId} = renderComponent()
      const commentsIcon = getByTestId('rubric-comment-button-1')
      expect(queryByTestId('comment-text-area-1')).toBeNull()

      fireEvent.click(commentsIcon)

      expect(getByTestId('comment-text-area-1')).toBeInTheDocument()
    })

    it('should close the comments tray when the comments icon is clicked again', () => {
      const {getByTestId, queryByTestId} = renderComponent()
      const commentsIcon = getByTestId('rubric-comment-button-1')
      fireEvent.click(commentsIcon)

      expect(getByTestId('comment-text-area-1')).toBeInTheDocument()

      fireEvent.click(commentsIcon)

      expect(queryByTestId('comment-text-area-1')).toBeNull()
    })

    it('should disable the toggle comment button when there is existing comments for criteria', () => {
      const rubricAssessmentData = [
        {
          criterionId: '1',
          points: 4,
          comments: 'existing comments',
          id: '1',
          commentsEnabled: true,
          description: 'description',
        },
      ]
      const {getByTestId} = renderComponent({rubricAssessmentData})
      const commentsIcon = getByTestId('rubric-comment-button-1')
      expect(commentsIcon).toBeDisabled()
    })

    it('should disable the toggle comment button after comments are added and blurred', () => {
      const {getByTestId} = renderComponent()
      const commentsIcon = getByTestId('rubric-comment-button-1')
      fireEvent.click(commentsIcon)

      const textArea = getByTestId('comment-text-area-1') as HTMLTextAreaElement
      fireEvent.change(textArea, {target: {value: 'new comments'}})
      fireEvent.blur(textArea)

      expect(commentsIcon).toBeDisabled()
    })
  })

  describe('Modern View tests', () => {
    const renderComponentModern = (viewMode: string, isPeerReview = false) => {
      const component = renderComponent({isPeerReview})
      const {getByTestId, queryByRole} = component
      const viewModeSelect = getByTestId('rubric-assessment-view-mode-select') as HTMLSelectElement

      fireEvent.click(viewModeSelect)
      const roleOption = queryByRole('option', {name: viewMode}) as HTMLElement
      fireEvent.click(roleOption)

      return component
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
})

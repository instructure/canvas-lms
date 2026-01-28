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

describe('RubricAssessmentTray Traditional View Tests', () => {
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

  it('should not render score input if criterion is ignoreForScoring', () => {
    const updatedRubric = {
      ...RUBRIC_DATA,
      criteria: RUBRIC_DATA.criteria.map(criterion =>
        criterion.id === '2' ? {...criterion, ignoreForScoring: true} : criterion,
      ),
    }

    const {queryByTestId} = renderComponent({rubric: updatedRubric})
    expect(queryByTestId('criterion-score-1')).toBeInTheDocument()
    expect(queryByTestId('criterion-score-2')).not.toBeInTheDocument()
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

    it('should set comment text when multiple comments are available and selected', () => {
      const {getByTestId} = renderFreeformComponent({
        rubricSavedComments: {1: ['Great work!', 'Needs improvement', 'Excellent effort']},
      })

      const commentLibrary = getByTestId('comment-library-1')
      fireEvent.click(commentLibrary)

      const firstCommentOption = getByTestId('comment-library-option-1-0') as HTMLElement
      fireEvent.click(firstCommentOption)

      const commentTextArea = getByTestId('free-form-comment-area-1')
      expect(commentTextArea).toHaveValue('Great work!')

      fireEvent.click(commentLibrary)
      const secondCommentOption = getByTestId('comment-library-option-1-1') as HTMLElement
      fireEvent.click(secondCommentOption)

      expect(commentTextArea).toHaveValue('Needs improvement')
      fireEvent.click(commentLibrary)

      const thirdCommentOption = getByTestId('comment-library-option-1-2') as HTMLElement
      fireEvent.click(thirdCommentOption)

      expect(commentTextArea).toHaveValue('Excellent effort')
    })

    it('should update comment text when a custom comment is typed', () => {
      const {getByTestId} = renderFreeformComponent({
        rubricSavedComments: {1: ['Good job', 'Needs improvement']},
      })

      const commentTextArea = getByTestId('free-form-comment-area-1')
      fireEvent.change(commentTextArea, {target: {value: 'This is a custom comment'}})

      expect(commentTextArea).toHaveValue('This is a custom comment')
    })
  })
})

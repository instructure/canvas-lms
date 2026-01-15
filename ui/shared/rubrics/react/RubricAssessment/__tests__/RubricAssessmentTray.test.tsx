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

describe('RubricAssessmentTray Tests', () => {
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
    const rubric = freeFormCriterionComments
      ? {...RUBRIC_DATA, freeFormCriterionComments: true}
      : RUBRIC_DATA
    return renderComponent({rubric, isPeerReview, ...props})
  }

  describe('Peer Review tests', () => {
    const renderPeerReviewComponent = () => {
      return renderComponent({isPeerReview: true})
    }

    it('should display the peer review text when in peer review mode', () => {
      const {getByTestId} = renderPeerReviewComponent()
      expect(getByTestId('rubric-assessment-header')).toHaveTextContent('Peer Review')
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
      it('should not allow users to select ratings when in preview mode', async () => {
        const {getByTestId, queryByTestId} = renderComponentModern('Horizontal', false, false, {
          isPreviewMode: true,
        })

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

  describe('selfAssessment test', () => {
    it('should display self assessment instructions and score', () => {
      const {getByTestId} = renderComponent({isSelfAssessment: true})
      expect(getByTestId('rubric-self-assessment-instructions')).toBeInTheDocument()
      expect(getByTestId('rubric-self-assessment-instructor-score')).toBeInTheDocument()
    })
  })
})

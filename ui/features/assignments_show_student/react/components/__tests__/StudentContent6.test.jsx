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
import {MockedProvider} from '@apollo/client/testing'
import {render, fireEvent} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import StudentContent from '../StudentContent'
import {withSubmissionContext} from '../../test-utils/submission-context'
import fakeENV from '@canvas/test-utils/fakeENV'
import store from '../stores'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

describe('Assignment Student Content View', () => {
  beforeAll(() => {
    fakeENV.setup()
  })

  afterAll(() => {
    fakeENV.teardown()
  })

  describe('self assessment', () => {
    beforeEach(() => {
      store.setState({
        selfAssessment: {
          data: null,
        },
        displayedAssessment: null,
        isSavingRubricAssessment: false,
      })
      fakeENV.setup({
        enhanced_rubrics_enabled: true,
        peerReviewModeEnabled: false,
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    const renderComponent = async (assignmentOverrides = {}, isSubmitted = true) => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...(isSubmitted
            ? {
                ...SubmissionMocks.submitted,
                state: 'submitted',
                submissionStatus: 'submitted',
                attempt: 1,
              }
            : SubmissionMocks.missing),
        },
      })
      props.assignment.rubric = {
        title: 'test rubric',
        criteria: [
          {
            id: '1',
            description: 'test criterion',
            longDescription: 'this is a test criterion',
            points: 10,
            ratings: [
              {
                id: 'rating_1_id',
                description: 'Rating 1',
                longDescription: 'Rating 1 long description',
                points: 10,
                criterionId: '1',
              },
              {
                id: 'rating_2_id',
                description: 'Rating 2',
                longDescription: 'Rating 2 long description',
                points: 0,
                criterionId: '2',
              },
            ],
          },
        ],
      }
      props.assignment.rubricSelfAssessmentEnabled = true
      props.assignment = {...props.assignment, ...assignmentOverrides}

      return render(
        <MockedProvider>
          {withSubmissionContext(<StudentContent {...props} />, {
            assignmentId: '1',
            submissionId: '1',
          })}
        </MockedProvider>,
      )
    }

    it('does not render self assessment button when feature flag is disabled', async () => {
      fakeENV.setup({enhanced_rubrics_enabled: false})
      const {queryByTestId} = await renderComponent()

      expect(queryByTestId('self-assess-button')).not.toBeInTheDocument()
    })

    it('does not render self assessment button without a rubric', async () => {
      const {queryByTestId} = await renderComponent({rubric: null})

      expect(queryByTestId('self-assess-button')).not.toBeInTheDocument()
    })

    it('does not render self assessment button when self assessment is disabled', async () => {
      const {queryByTestId} = await renderComponent({rubricSelfAssessmentEnabled: false})

      expect(queryByTestId('self-assess-button')).not.toBeInTheDocument()
    })

    it('does not render self assessment button in peer review mode', async () => {
      fakeENV.setup({peerReviewModeEnabled: true})
      const {queryByTestId} = await renderComponent()

      expect(queryByTestId('self-assess-button')).not.toBeInTheDocument()
    })

    it('renders disabled self assessment button when assignment is not submitted', async () => {
      const {getByTestId} = await renderComponent({}, false)

      expect(getByTestId('self-assess-button')).toBeDisabled()
    })

    it('renders enabled self assessment button when assignment is submitted', async () => {
      const {getByTestId} = await renderComponent()

      expect(getByTestId('self-assess-button')).toBeEnabled()
    })

    it('opens rubric assessment tray on self assessment button click', async () => {
      store.setState({
        displayedAssessment: {
          data: [
            {
              criterion_id: '1',
              points: {value: 10, valid: true},
              description: 'Rating 1',
              comments: '',
            },
          ],
        },
        isSavingRubricAssessment: false,
        selfAssessment: null,
      })
      const {getByTestId} = await renderComponent()

      fireEvent.click(getByTestId('self-assess-button'))

      // First verify the tray opens
      expect(getByTestId('enhanced-rubric-assessment-tray')).toBeInTheDocument()
      expect(getByTestId('rubric-assessment-horizontal-display')).toBeInTheDocument()
      expect(getByTestId('rubric-self-assessment-instructions')).toBeInTheDocument()

      // Then verify the buttons are enabled
      const ratingButton1 = getByTestId('rubric-self-assessment-rating-button-1')
      const ratingButton0 = getByTestId('rubric-self-assessment-rating-button-0')

      expect(ratingButton1).not.toHaveAttribute('disabled')
      expect(ratingButton0).not.toHaveAttribute('disabled')
    })

    it('shows read-only rubric assessment tray when already self assessed', async () => {
      store.setState({
        selfAssessment: {
          data: [
            {
              points: 10,
              criterion_id: '1',
              id: 'rating_1_id',
            },
          ],
        },
      })
      const {getByTestId} = await renderComponent()

      fireEvent.click(getByTestId('self-assess-button'))

      expect(getByTestId('enhanced-rubric-assessment-tray')).toBeInTheDocument()
      expect(getByTestId('rubric-assessment-horizontal-display')).toBeInTheDocument()
      expect(getByTestId('rubric-self-assessment-instructions')).toBeInTheDocument()
      expect(getByTestId('rubric-self-assessment-rating-button-1')).toBeDisabled()
      expect(getByTestId('rubric-self-assessment-rating-button-selected')).toBeInTheDocument()
      expect(getByTestId('rubric-self-assessment-rating-button-0')).toBeDisabled()
    })
  })
})

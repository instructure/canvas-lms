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
import userEvent from '@testing-library/user-event'
import {RubricPanel} from '../RubricPanel'
import type {RubricAssessmentData} from '@canvas/rubrics/react/types/rubric'

vi.mock('@canvas/rubrics/react/RubricAssessment', () => ({
  RubricAssessmentContainerWrapper: (props: any) => (
    <div data-testid="mocked-rubric-assessment" data-props={JSON.stringify(props)}>
      Mocked Rubric Assessment
      <button
        data-testid="mocked-rubric-submit"
        onClick={() =>
          props.onSubmit([
            {
              id: 'rating-1',
              points: 4,
              criterionId: '1',
              comments: 'Test',
              commentsEnabled: true,
              description: 'Excellent',
            },
          ])
        }
      >
        Submit
      </button>
    </div>
  ),
}))

describe('RubricPanel', () => {
  const createRubric = (overrides = {}) => ({
    _id: '3',
    title: 'Test Rubric',
    criteria: [
      {
        _id: '1',
        description: 'Quality',
        long_description: 'Quality of work',
        points: 4,
        criterion_use_range: false,
        ratings: [
          {
            _id: 'rating-1',
            description: 'Excellent',
            long_description: '',
            points: 4,
          },
          {
            _id: 'rating-2',
            description: 'Good',
            long_description: '',
            points: 3,
          },
        ],
        ignore_for_scoring: false,
      },
    ],
    free_form_criterion_comments: false,
    hide_score_total: false,
    points_possible: 4,
    ratingOrder: 'descending' as const,
    button_display: 'numeric',
    ...overrides,
  })

  const createRubricAssociation = (overrides = {}) => ({
    _id: '1',
    hide_points: false,
    hide_score_total: false,
    use_for_grading: true,
    ...overrides,
  })

  const createAssignment = (overrides = {}) => ({
    _id: '1',
    name: 'Test Assignment',
    dueAt: null,
    description: null,
    expectsSubmission: true,
    nonDigitalSubmission: false,
    pointsPossible: 10,
    courseId: '1',
    peerReviews: null,
    submissionsConnection: null,
    assignedToDates: null,
    assessmentRequestsForCurrentUser: null,
    rubric: createRubric(),
    rubricAssociation: createRubricAssociation(),
    ...overrides,
  })

  const createDefaultProps = (overrides = {}) => ({
    assignment: createAssignment(),
    rubricAssessmentData: [] as RubricAssessmentData[],
    rubricViewMode: 'vertical' as const,
    isPeerReviewCompleted: false,
    rubricAssessmentCompleted: false,
    onClose: vi.fn(),
    onSubmit: vi.fn(),
    onViewModeChange: vi.fn(),
    ...overrides,
  })

  it('renders without crashing', () => {
    render(<RubricPanel {...createDefaultProps()} />)
    expect(screen.getByTestId('mocked-rubric-assessment')).toBeInTheDocument()
  })

  it('renders heading with correct text', () => {
    render(<RubricPanel {...createDefaultProps()} />)
    expect(screen.getByText('Peer Review Rubric')).toBeInTheDocument()
  })

  it('renders close button', () => {
    render(<RubricPanel {...createDefaultProps()} />)
    expect(screen.getByTestId('close-rubric-button')).toBeInTheDocument()
  })

  it('calls onClose when close button is clicked', async () => {
    const user = userEvent.setup()
    const mockOnClose = vi.fn()
    render(<RubricPanel {...createDefaultProps({onClose: mockOnClose})} />)

    const closeButtonContainer = screen.getByTestId('close-rubric-button')
    const button = closeButtonContainer.querySelector('button')
    if (button) {
      await user.click(button)
    }

    expect(mockOnClose).toHaveBeenCalledTimes(1)
  })

  it('returns null when assignment has no rubric', () => {
    const assignment = createAssignment({rubric: null})
    const {container} = render(<RubricPanel {...createDefaultProps({assignment})} />)
    expect(container.firstChild).toBeNull()
  })

  it('passes correct props to RubricAssessmentContainerWrapper', () => {
    const assignment = createAssignment()
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.rubricTitle).toBe('Test Rubric')
    expect(props.pointsPossible).toBe(4)
    expect(props.isPeerReview).toBe(true)
    expect(props.buttonDisplay).toBe('numeric')
    expect(props.ratingOrder).toBe('descending')
  })

  it('passes criteria with correct structure', () => {
    const assignment = createAssignment()
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.criteria).toHaveLength(1)
    expect(props.criteria[0]).toMatchObject({
      id: '1',
      description: 'Quality',
      longDescription: 'Quality of work',
      points: 4,
      criterionUseRange: false,
      ignoreForScoring: false,
    })
  })

  it('passes ratings with correct structure', () => {
    const assignment = createAssignment()
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.criteria[0].ratings).toHaveLength(2)
    expect(props.criteria[0].ratings[0]).toMatchObject({
      id: 'rating-1',
      description: 'Excellent',
      longDescription: '',
      points: 4,
      criterionId: '1',
    })
  })

  it('sets isPreviewMode to true when isPeerReviewCompleted is true', () => {
    render(<RubricPanel {...createDefaultProps({isPeerReviewCompleted: true})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.isPreviewMode).toBe(true)
  })

  it('sets isPreviewMode to true when rubricAssessmentCompleted is true', () => {
    render(<RubricPanel {...createDefaultProps({rubricAssessmentCompleted: true})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.isPreviewMode).toBe(true)
  })

  it('sets isPreviewMode to false when neither completed flags are true', () => {
    render(
      <RubricPanel
        {...createDefaultProps({
          isPeerReviewCompleted: false,
          rubricAssessmentCompleted: false,
        })}
      />,
    )

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.isPreviewMode).toBe(false)
  })

  it('passes rubricAssessmentData to RubricAssessmentContainerWrapper', () => {
    const rubricAssessmentData: RubricAssessmentData[] = [
      {
        id: 'rating-1',
        points: 4,
        criterionId: '1',
        comments: 'Great work',
        commentsEnabled: true,
        description: 'Excellent',
      },
    ]
    render(<RubricPanel {...createDefaultProps({rubricAssessmentData})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.rubricAssessmentData).toEqual(rubricAssessmentData)
  })

  it('passes viewModeOverride to RubricAssessmentContainerWrapper', () => {
    render(<RubricPanel {...createDefaultProps({rubricViewMode: 'horizontal'})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.viewModeOverride).toBe('horizontal')
  })

  it('calls onSubmit when rubric is submitted', async () => {
    const user = userEvent.setup()
    const mockOnSubmit = vi.fn()
    render(<RubricPanel {...createDefaultProps({onSubmit: mockOnSubmit})} />)

    const submitButton = screen.getByTestId('mocked-rubric-submit')
    await user.click(submitButton)

    expect(mockOnSubmit).toHaveBeenCalledTimes(1)
    expect(mockOnSubmit).toHaveBeenCalledWith([
      {
        id: 'rating-1',
        points: 4,
        criterionId: '1',
        comments: 'Test',
        commentsEnabled: true,
        description: 'Excellent',
      },
    ])
  })

  it('hides points when rubricAssociation.hide_points is true', () => {
    const assignment = createAssignment({
      rubricAssociation: createRubricAssociation({hide_points: true}),
    })
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.hidePoints).toBe(true)
  })

  it('shows points when rubricAssociation.hide_points is false', () => {
    const assignment = createAssignment({
      rubricAssociation: createRubricAssociation({hide_points: false}),
    })
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.hidePoints).toBe(false)
  })

  it('handles rubric with free form criterion comments', () => {
    const rubric = createRubric({free_form_criterion_comments: true})
    const assignment = createAssignment({rubric})
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.isFreeFormCriterionComments).toBe(true)
  })

  it('handles rubric with level button display', () => {
    const rubric = createRubric({button_display: 'level'})
    const assignment = createAssignment({rubric})
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.buttonDisplay).toBe('level')
  })

  it('handles rubric with ascending rating order', () => {
    const rubric = createRubric({ratingOrder: 'ascending'})
    const assignment = createAssignment({rubric})
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.ratingOrder).toBe('ascending')
  })

  it('handles criteria with learning outcome', () => {
    const rubric = createRubric({
      criteria: [
        {
          _id: '1',
          description: 'Quality',
          long_description: 'Quality of work',
          points: 4,
          criterion_use_range: false,
          learning_outcome_id: 'outcome-1',
          mastery_points: 3,
          ratings: [],
          ignore_for_scoring: false,
        },
      ],
    })
    const assignment = createAssignment({rubric})
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.criteria[0].learningOutcomeId).toBe('outcome-1')
    expect(props.criteria[0].masteryPoints).toBe(3)
  })

  it('handles criteria with criterion_use_range', () => {
    const rubric = createRubric({
      criteria: [
        {
          _id: '1',
          description: 'Quality',
          long_description: 'Quality of work',
          points: 4,
          criterion_use_range: true,
          ratings: [],
          ignore_for_scoring: false,
        },
      ],
    })
    const assignment = createAssignment({rubric})
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.criteria[0].criterionUseRange).toBe(true)
  })

  it('handles criteria with ignore_for_scoring', () => {
    const rubric = createRubric({
      criteria: [
        {
          _id: '1',
          description: 'Quality',
          long_description: 'Quality of work',
          points: 4,
          criterion_use_range: false,
          ratings: [],
          ignore_for_scoring: true,
        },
      ],
    })
    const assignment = createAssignment({rubric})
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.criteria[0].ignoreForScoring).toBe(true)
  })

  it('uses current user ID from ENV', () => {
    const originalUserId = ENV.current_user_id
    ENV.current_user_id = '999'

    render(<RubricPanel {...createDefaultProps()} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.currentUserId).toBe('999')

    ENV.current_user_id = originalUserId
  })

  it('handles missing current user ID', () => {
    const originalUserId = ENV.current_user_id
    ENV.current_user_id = null

    render(<RubricPanel {...createDefaultProps()} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.currentUserId).toBe('')

    ENV.current_user_id = originalUserId
  })
})

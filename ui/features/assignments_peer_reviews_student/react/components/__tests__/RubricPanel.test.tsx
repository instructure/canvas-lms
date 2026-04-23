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

vi.mock('@canvas/rubrics/react/RubricAssessment', () => {
  const {useEffect, useRef} = require('react')

  const RubricAssessmentContainerWrapper = (props: any) => {
    const criteria = props.criteria || []
    const assessmentData = props.rubricAssessmentData || []
    const hidePoints = props.hidePoints || false
    const isFreeForm = props.isFreeFormCriterionComments || false
    const containerRef = useRef(null)
    const submitButtonRef = useRef(null)

    useEffect(() => {
      if (!props.triggerValidationAndFocus) return
      if (!containerRef.current) return

      const container = containerRef.current as HTMLDivElement

      const firstIncomplete = criteria.find((criterion: any) => {
        const assessment = assessmentData.find((d: any) => d.criterionId === criterion.id)
        if (!hidePoints) return !assessment?.points && assessment?.points !== 0
        if (isFreeForm) return !assessment?.comments
        return !assessment
      })

      if (!firstIncomplete) {
        ;(submitButtonRef.current as HTMLButtonElement | null)?.focus()
        return
      }

      if (!hidePoints) {
        const input = container.querySelector(
          `[data-criterion-score-id="${firstIncomplete.id}"]`,
        ) as HTMLInputElement | null
        input?.focus()
      } else if (isFreeForm) {
        const commentArea = container.querySelector(
          `[data-criterion-comment-id="${firstIncomplete.id}"]`,
        ) as HTMLTextAreaElement | null
        commentArea?.focus()
      } else {
        const ratingContainer = container.querySelector(
          `[data-criterion-id="${firstIncomplete.id}"]`,
        ) as Element | null
        const firstButton = ratingContainer?.querySelector('button') as HTMLButtonElement | null
        firstButton?.focus()
      }
    }, [props.triggerValidationAndFocus])

    const renderCriterionInput = (criterion: any) => {
      const assessment = assessmentData.find((d: any) => d.criterionId === criterion.id)
      if (!hidePoints) {
        return (
          <input
            key={criterion.id}
            data-criterion-score-id={criterion.id}
            data-testid={`criterion-score-${criterion.id}`}
            defaultValue={assessment?.points?.toString() ?? ''}
          />
        )
      } else if (isFreeForm) {
        return (
          <textarea
            key={criterion.id}
            data-criterion-comment-id={criterion.id}
            data-testid={`free-form-comment-area-${criterion.id}`}
            defaultValue={assessment?.comments ?? ''}
          />
        )
      } else {
        const isSelected = !!assessment
        return (
          <div key={criterion.id} data-criterion-id={criterion.id}>
            <button data-testid={`rate-criterion-${criterion.id}`}>Rate</button>
            {isSelected && <div data-testid="rubric-rating-button-selected" />}
          </div>
        )
      }
    }

    return (
      <div
        ref={containerRef}
        data-testid="mocked-rubric-assessment"
        data-props={JSON.stringify(props)}
      >
        {criteria.map(renderCriterionInput)}
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
        <button ref={submitButtonRef} data-testid="save-rubric-assessment-button">
          Submit Assessment
        </button>
      </div>
    )
  }

  return {
    RubricAssessmentContainerWrapper,
    RubricAssessmentTray: (props: any) => (
      <div data-testid="mocked-rubric-assessment-tray" data-props={JSON.stringify(props)}>
        Mocked Rubric Assessment Tray
      </div>
    ),
  }
})

describe('RubricPanel', () => {
  const createRubric = (overrides = {}) => ({
    _id: '3',
    title: 'Test Rubric',
    criteria: [
      {
        _id: '1',
        description: 'Quality',
        longDescription: 'Quality of work',
        points: 4,
        criterionUseRange: false,
        ratings: [
          {
            _id: 'rating-1',
            description: 'Excellent',
            longDescription: '',
            points: 4,
          },
          {
            _id: 'rating-2',
            description: 'Good',
            longDescription: '',
            points: 3,
          },
        ],
        ignoreForScoring: false,
      },
    ],
    freeFormCriterionComments: false,
    hideScoreTotal: false,
    pointsPossible: 4,
    ratingOrder: 'descending' as const,
    buttonDisplay: 'numeric',
    ...overrides,
  })

  const createRubricAssociation = (overrides = {}) => ({
    _id: '1',
    hidePoints: false,
    hideScoreTotal: false,
    useForGrading: true,
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
    peerReviewSubAssignment: null,
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

  it('passes isStandaloneContainer as true to prevent duplicate close button', () => {
    render(<RubricPanel {...createDefaultProps()} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.isStandaloneContainer).toBe(true)
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

  it('hides points when rubricAssociation.hidePoints is true', () => {
    const assignment = createAssignment({
      rubricAssociation: createRubricAssociation({hidePoints: true}),
    })
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.hidePoints).toBe(true)
  })

  it('shows points when rubricAssociation.hidePoints is false', () => {
    const assignment = createAssignment({
      rubricAssociation: createRubricAssociation({hidePoints: false}),
    })
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.hidePoints).toBe(false)
  })

  it('handles rubric with free form criterion comments', () => {
    const rubric = createRubric({freeFormCriterionComments: true})
    const assignment = createAssignment({rubric})
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.isFreeFormCriterionComments).toBe(true)
  })

  it('handles rubric with level button display', () => {
    const rubric = createRubric({buttonDisplay: 'level'})
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
          longDescription: 'Quality of work',
          points: 4,
          criterionUseRange: false,
          learningOutcomeId: 'outcome-1',
          masteryPoints: 3,
          ratings: [],
          ignoreForScoring: false,
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

  it('handles criteria with criterionUseRange', () => {
    const rubric = createRubric({
      criteria: [
        {
          _id: '1',
          description: 'Quality',
          longDescription: 'Quality of work',
          points: 4,
          criterionUseRange: true,
          ratings: [],
          ignoreForScoring: false,
        },
      ],
    })
    const assignment = createAssignment({rubric})
    render(<RubricPanel {...createDefaultProps({assignment})} />)

    const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
    const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

    expect(props.criteria[0].criterionUseRange).toBe(true)
  })

  it('handles criteria with ignoreForScoring', () => {
    const rubric = createRubric({
      criteria: [
        {
          _id: '1',
          description: 'Quality',
          longDescription: 'Quality of work',
          points: 4,
          criterionUseRange: false,
          ratings: [],
          ignoreForScoring: true,
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

  describe('Unscored rubric', () => {
    it('hides points and uses free-form comments when rubric is configured as unscored', () => {
      const assignment = createAssignment({
        rubric: createRubric({freeFormCriterionComments: true}),
        rubricAssociation: createRubricAssociation({hidePoints: true}),
      })
      render(
        <RubricPanel
          {...createDefaultProps({
            assignment,
            isPeerReviewCompleted: false,
            rubricAssessmentCompleted: false,
          })}
        />,
      )

      const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
      const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

      expect(props.hidePoints).toBe(true)
      expect(props.isFreeFormCriterionComments).toBe(true)
    })

    it('hides points and uses free-form comments for unscored rubric in mobile mode', () => {
      const assignment = createAssignment({
        rubric: createRubric({freeFormCriterionComments: true}),
        rubricAssociation: createRubricAssociation({hidePoints: true}),
      })
      render(
        <RubricPanel
          {...createDefaultProps({
            assignment,
            isMobile: true,
            isPeerReviewCompleted: false,
            rubricAssessmentCompleted: false,
          })}
        />,
      )

      const tray = screen.getByTestId('mocked-rubric-assessment-tray')
      const props = JSON.parse(tray.getAttribute('data-props') || '{}')

      expect(props.hidePoints).toBe(true)
    })

    it('does not hide points for scored rubric', () => {
      const assignment = createAssignment({
        rubric: createRubric({freeFormCriterionComments: false}),
        rubricAssociation: createRubricAssociation({hidePoints: false}),
      })
      render(<RubricPanel {...createDefaultProps({assignment})} />)

      const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
      const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

      expect(props.hidePoints).toBe(false)
      expect(props.isFreeFormCriterionComments).toBe(false)
    })
  })

  describe('Read-only mode', () => {
    it('sets isPreviewMode to true when isReadOnly is true', () => {
      render(<RubricPanel {...createDefaultProps({isReadOnly: true})} />)

      const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
      const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

      expect(props.isPreviewMode).toBe(true)
    })

    it('sets isPreviewMode to false when isReadOnly is false', () => {
      render(
        <RubricPanel
          {...createDefaultProps({
            isReadOnly: false,
            isPeerReviewCompleted: false,
            rubricAssessmentCompleted: false,
          })}
        />,
      )

      const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
      const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

      expect(props.isPreviewMode).toBe(false)
    })

    it('sets isPreviewMode to true when isReadOnly is true even if other completed flags are false', () => {
      render(
        <RubricPanel
          {...createDefaultProps({
            isReadOnly: true,
            isPeerReviewCompleted: false,
            rubricAssessmentCompleted: false,
          })}
        />,
      )

      const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
      const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

      expect(props.isPreviewMode).toBe(true)
    })

    it('defaults isReadOnly to false when not provided', () => {
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

    it('sets isPreviewMode to true when multiple conditions are met (completed + readOnly)', () => {
      render(
        <RubricPanel
          {...createDefaultProps({
            isReadOnly: true,
            isPeerReviewCompleted: true,
            rubricAssessmentCompleted: false,
          })}
        />,
      )

      const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
      const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

      expect(props.isPreviewMode).toBe(true)
    })
  })

  describe('triggerValidationAndFocus', () => {
    const twoCriteriaRubric = (extraRubricProps = {}) =>
      createRubric({
        criteria: [
          {
            _id: '1',
            description: 'Quality',
            longDescription: '',
            points: 4,
            criterionUseRange: false,
            ratings: [],
            ignoreForScoring: false,
          },
          {
            _id: '2',
            description: 'Effort',
            longDescription: '',
            points: 4,
            criterionUseRange: false,
            ratings: [],
            ignoreForScoring: false,
          },
        ],
        ...extraRubricProps,
      })

    const criterion1Data: RubricAssessmentData = {
      id: 'rating-1',
      points: 4,
      criterionId: '1',
      comments: 'Great work',
      commentsEnabled: true,
      description: 'Excellent',
    }

    describe('Scale type and Unscored', () => {
      const assignment = () =>
        createAssignment({rubricAssociation: createRubricAssociation({hidePoints: true})})

      it('focuses first incomplete criterion rating button when triggered', () => {
        render(
          <RubricPanel
            {...createDefaultProps({assignment: assignment(), triggerValidationAndFocus: 1})}
          />,
        )
        expect(screen.getByTestId('rate-criterion-1')).toHaveFocus()
      })

      it('skips completed criteria and focuses first incomplete one', () => {
        render(
          <RubricPanel
            {...createDefaultProps({
              assignment: createAssignment({
                rubric: twoCriteriaRubric(),
                rubricAssociation: createRubricAssociation({hidePoints: true}),
              }),
              rubricAssessmentData: [criterion1Data],
              triggerValidationAndFocus: 1,
            })}
          />,
        )
        expect(screen.getByTestId('rate-criterion-2')).toHaveFocus()
      })

      it('focuses Submit Assessment button when all criteria have ratings', () => {
        render(
          <RubricPanel
            {...createDefaultProps({
              assignment: assignment(),
              rubricAssessmentData: [criterion1Data],
              triggerValidationAndFocus: 1,
            })}
          />,
        )
        expect(screen.getByTestId('save-rubric-assessment-button')).toHaveFocus()
      })
    })

    describe('Written feedback type and Unscored', () => {
      const assignment = () =>
        createAssignment({
          rubric: createRubric({freeFormCriterionComments: true}),
          rubricAssociation: createRubricAssociation({hidePoints: true}),
        })

      it('focuses first criterion free-form comment area when triggered', () => {
        render(
          <RubricPanel
            {...createDefaultProps({assignment: assignment(), triggerValidationAndFocus: 1})}
          />,
        )
        expect(screen.getByTestId('free-form-comment-area-1')).toHaveFocus()
      })

      it('skips completed criteria and focuses first incomplete one', () => {
        render(
          <RubricPanel
            {...createDefaultProps({
              assignment: createAssignment({
                rubric: twoCriteriaRubric({freeFormCriterionComments: true}),
                rubricAssociation: createRubricAssociation({hidePoints: true}),
              }),
              rubricAssessmentData: [criterion1Data],
              triggerValidationAndFocus: 1,
            })}
          />,
        )
        expect(screen.getByTestId('free-form-comment-area-2')).toHaveFocus()
      })

      it('focuses Submit Assessment button when all criteria have comments', () => {
        render(
          <RubricPanel
            {...createDefaultProps({
              assignment: assignment(),
              rubricAssessmentData: [criterion1Data],
              triggerValidationAndFocus: 1,
            })}
          />,
        )
        expect(screen.getByTestId('save-rubric-assessment-button')).toHaveFocus()
      })
    })

    describe('Scored', () => {
      const assignment = () =>
        createAssignment({rubricAssociation: createRubricAssociation({hidePoints: false})})

      it('focuses first criterion score input when triggered', () => {
        render(
          <RubricPanel
            {...createDefaultProps({assignment: assignment(), triggerValidationAndFocus: 1})}
          />,
        )
        expect(screen.getByTestId('criterion-score-1')).toHaveFocus()
      })

      it('skips completed criteria and focuses first incomplete one', () => {
        render(
          <RubricPanel
            {...createDefaultProps({
              assignment: createAssignment({
                rubric: twoCriteriaRubric(),
                rubricAssociation: createRubricAssociation({hidePoints: false}),
              }),
              rubricAssessmentData: [criterion1Data],
              triggerValidationAndFocus: 1,
            })}
          />,
        )
        expect(screen.getByTestId('criterion-score-2')).toHaveFocus()
      })

      it('focuses Submit Assessment button when all criteria have scores', () => {
        render(
          <RubricPanel
            {...createDefaultProps({
              assignment: assignment(),
              rubricAssessmentData: [criterion1Data],
              triggerValidationAndFocus: 1,
            })}
          />,
        )
        expect(screen.getByTestId('save-rubric-assessment-button')).toHaveFocus()
      })
    })

    it('does not focus anything when trigger is 0', () => {
      const assignment = createAssignment({
        rubricAssociation: createRubricAssociation({hidePoints: true}),
      })
      render(<RubricPanel {...createDefaultProps({assignment, triggerValidationAndFocus: 0})} />)
      expect(screen.getByTestId('rate-criterion-1')).not.toHaveFocus()
      expect(screen.getByTestId('save-rubric-assessment-button')).not.toHaveFocus()
    })
  })

  describe('Mobile mode', () => {
    it('renders RubricAssessmentTray when isMobile is true', () => {
      render(<RubricPanel {...createDefaultProps({isMobile: true})} />)
      expect(screen.getByTestId('mocked-rubric-assessment-tray')).toBeInTheDocument()
      expect(screen.queryByTestId('mocked-rubric-assessment')).not.toBeInTheDocument()
    })

    it('renders inline RubricAssessmentContainerWrapper when isMobile is false', () => {
      render(<RubricPanel {...createDefaultProps({isMobile: false})} />)
      expect(screen.getByTestId('mocked-rubric-assessment')).toBeInTheDocument()
      expect(screen.queryByTestId('mocked-rubric-assessment-tray')).not.toBeInTheDocument()
    })

    it('passes correct rubric props to RubricAssessmentTray', () => {
      render(<RubricPanel {...createDefaultProps({isMobile: true})} />)

      const tray = screen.getByTestId('mocked-rubric-assessment-tray')
      const props = JSON.parse(tray.getAttribute('data-props') || '{}')

      expect(props.isOpen).toBe(true)
      expect(props.isPeerReview).toBe(true)
      expect(props.rubric.title).toBe('Test Rubric')
      expect(props.rubric.pointsPossible).toBe(4)
      expect(props.rubric.criteria).toHaveLength(1)
      expect(props.rubric.criteria[0].id).toBe('1')
    })

    it('passes isPreviewMode correctly to RubricAssessmentTray', () => {
      render(<RubricPanel {...createDefaultProps({isMobile: true, isPeerReviewCompleted: true})} />)

      const tray = screen.getByTestId('mocked-rubric-assessment-tray')
      const props = JSON.parse(tray.getAttribute('data-props') || '{}')

      expect(props.isPreviewMode).toBe(true)
    })

    it('returns null when assignment has no rubric in mobile mode', () => {
      const assignment = createAssignment({rubric: null})
      const {container} = render(
        <RubricPanel {...createDefaultProps({assignment, isMobile: true})} />,
      )
      expect(container.firstChild).toBeNull()
    })
  })
})

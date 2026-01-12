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

import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import {renderHook} from '@testing-library/react-hooks'
import {useRubricAssessment} from '../useRubricAssessment'
import type {Assignment} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

type UseRubricAssessmentReturn = ReturnType<typeof useRubricAssessment>

vi.mock('@canvas/do-fetch-api-effect')
vi.mock('@canvas/local-storage', () => ({
  default: () => ['vertical', vi.fn()],
}))
vi.mock('@canvas/rubrics/react/RubricAssessment/constants', () => ({
  RUBRIC_VIEW_MODE_LOCALSTORAGE_KEY: () => 'rubric_view_mode',
}))

describe('useRubricAssessment', () => {
  const createWrapper = () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    return ({
      children,
      isPeerReviewCompleted,
    }: React.PropsWithChildren<{isPeerReviewCompleted?: boolean}>) => (
      <MockedQueryClientProvider client={queryClient}>{children}</MockedQueryClientProvider>
    )
  }

  const testAssignment: Assignment = {
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
    rubric: {
      _id: '3',
      title: 'Test Rubric',
      criteria: [],
      free_form_criterion_comments: false,
      hide_score_total: false,
      points_possible: 4,
      ratingOrder: 'descending' as const,
      button_display: 'numeric',
    },
    rubricAssociation: {
      _id: '1',
      hide_points: false,
      hide_score_total: false,
      use_for_grading: true,
    },
  }

  it('initializes with defined hook values', () => {
    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current).toBeDefined()
    expect(result.current.rubricAssessmentData).toBeDefined()
    expect(result.current.rubricAssessmentCompleted).toBeDefined()
    expect(result.current.rubricViewMode).toBeDefined()
  })

  it('initializes with empty rubric assessment data when no assessment provided', () => {
    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment: null,
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.rubricAssessmentData).toEqual([])
    expect(result.current.rubricAssessmentCompleted).toBe(false)
  })

  it('initializes with vertical view mode', () => {
    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.rubricViewMode).toBe('vertical')
  })

  it('resets rubric assessment completed status', () => {
    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment: null,
          isPeerReviewCompleted: true,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.rubricAssessmentCompleted).toBe(false)

    result.current.resetRubricAssessment()

    expect(result.current.rubricAssessmentCompleted).toBe(false)
  })

  it('provides handleRubricSubmit function', () => {
    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.handleRubricSubmit).toBeDefined()
    expect(typeof result.current.handleRubricSubmit).toBe('function')
  })

  it('provides setRubricViewMode function', () => {
    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.setRubricViewMode).toBeDefined()
    expect(typeof result.current.setRubricViewMode).toBe('function')
  })

  it('initializes with rubric assessment data when assessment is provided', () => {
    const rubricAssessment = {
      _id: 'assessment-1',
      assessmentRatings: [
        {
          _id: 'rating-1',
          points: 4,
          criterion: {
            _id: '1',
          },
          comments: 'Great work',
        },
      ],
    }

    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment,
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.rubricAssessmentData).toHaveLength(1)
    expect(result.current.rubricAssessmentData[0]).toMatchObject({
      id: 'rating-1',
      points: 4,
      criterionId: '1',
      comments: 'Great work',
    })
  })

  it('sets rubricAssessmentCompleted to true when assessment is provided and peer review is completed', () => {
    const rubricAssessment = {
      _id: 'assessment-1',
      assessmentRatings: [
        {
          _id: 'rating-1',
          points: 4,
          criterion: {
            _id: '1',
          },
          comments: 'Good',
        },
      ],
    }

    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment,
          isPeerReviewCompleted: true,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.rubricAssessmentCompleted).toBe(true)
  })

  it('handles rubric assessment with multiple ratings', () => {
    const rubricAssessment = {
      _id: 'assessment-1',
      assessmentRatings: [
        {
          _id: 'rating-1',
          points: 4,
          criterion: {
            _id: '1',
          },
          comments: 'Excellent',
        },
        {
          _id: 'rating-2',
          points: 3,
          criterion: {
            _id: '1',
          },
          comments: 'Good effort',
        },
      ],
    }

    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment,
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.rubricAssessmentData).toHaveLength(2)
    expect(result.current.rubricAssessmentData[0].criterionId).toBe('1')
    expect(result.current.rubricAssessmentData[1].criterionId).toBe('1')
  })

  it('handles submission with userId', () => {
    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          submissionUserId: 'user-123',
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current).toBeDefined()
  })

  it('handles submission with anonymousId', () => {
    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          submissionAnonymousId: 'anon-456',
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current).toBeDefined()
  })

  it('returns empty assessment data when rubric assessment has no ratings', () => {
    const rubricAssessment = {
      _id: 'assessment-1',
      assessmentRatings: [],
    }

    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment,
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.rubricAssessmentData).toEqual([])
  })

  it('handles assessment ratings with missing optional fields', () => {
    const rubricAssessment = {
      _id: 'assessment-1',
      assessmentRatings: [
        {
          _id: 'rating-1',
          points: 4,
          criterion: {
            _id: '1',
          },
        },
      ],
    }

    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment,
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    expect(result.current.rubricAssessmentData).toHaveLength(1)
    expect(result.current.rubricAssessmentData[0]).toMatchObject({
      id: 'rating-1',
      points: 4,
      criterionId: '1',
    })
  })

  it('maintains stable rubric assessment data when isPeerReviewCompleted changes', () => {
    const {result, rerender} = renderHook<
      {isPeerReviewCompleted: boolean},
      UseRubricAssessmentReturn
    >(
      ({isPeerReviewCompleted}) =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          isPeerReviewCompleted,
        }),
      {
        wrapper: createWrapper(),
        initialProps: {isPeerReviewCompleted: false},
      },
    )

    const initialData = result.current.rubricAssessmentData

    rerender({isPeerReviewCompleted: true})

    expect(result.current.rubricAssessmentData).toEqual(initialData)
  })

  it('maintains rubricAssessmentCompleted when assessment is provided regardless of isPeerReviewCompleted', () => {
    const rubricAssessment = {
      _id: 'assessment-1',
      assessmentRatings: [
        {
          _id: 'rating-1',
          points: 4,
          criterion: {
            _id: '1',
          },
          comments: 'Test',
        },
      ],
    }

    const {result, rerender} = renderHook<
      {isPeerReviewCompleted: boolean},
      UseRubricAssessmentReturn
    >(
      ({isPeerReviewCompleted}) =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment,
          isPeerReviewCompleted,
        }),
      {
        wrapper: createWrapper(),
        initialProps: {isPeerReviewCompleted: true},
      },
    )

    expect(result.current.rubricAssessmentCompleted).toBe(true)

    rerender({isPeerReviewCompleted: false})

    expect(result.current.rubricAssessmentCompleted).toBe(true)
  })

  it('transforms assessment ratings to correct format', () => {
    const rubricAssessment = {
      _id: 'assessment-1',
      assessmentRatings: [
        {
          _id: 'rating-abc',
          points: 4,
          criterion: {
            _id: '1',
          },
          comments: 'Excellent work!',
        },
      ],
    }

    const {result} = renderHook(
      () =>
        useRubricAssessment({
          assignment: testAssignment,
          submissionId: 'sub1',
          rubricAssessment,
          isPeerReviewCompleted: false,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    const assessmentData = result.current.rubricAssessmentData[0]
    expect(assessmentData.id).toBe('rating-abc')
    expect(assessmentData.points).toBe(4)
    expect(assessmentData.criterionId).toBe('1')
    expect(assessmentData.comments).toBe('Excellent work!')
    expect(assessmentData).toHaveProperty('commentsEnabled')
  })
})

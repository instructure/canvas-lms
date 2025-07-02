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
import {renderHook} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/client/testing'
import {useSubmissionWorkflow} from '../hooks/useSubmissionWorkflow'
import {withSubmissionContext} from '../test-utils/submission-context'
import {STUDENT_VIEW_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {createCache} from '@canvas/apollo-v3'

describe('useSubmissionWorkflow', () => {
  const createMock = (submissionOverrides = {}, assignmentOverrides = {}) => [
    {
      delay: 30,
      request: {
        query: STUDENT_VIEW_QUERY,
        variables: {
          assignmentLid: '1',
          submissionID: '2',
        },
      },
      result: {
        data: {
          submission: {
            __typename: 'Submission',
            _id: '2',
            id: '2',
            attachment: null,
            attachments: [],
            attempt: 1,
            body: null,
            deductedPoints: null,
            enteredGrade: '60',
            gradedAnonymously: false,
            hideGradeFromStudent: false,
            extraAttempts: null,
            grade: '60',
            gradeHidden: false,
            gradingStatus: 'needs_review',
            customGradeStatus: '',
            latePolicyStatus: null,
            mediaObject: null,
            originalityData: {},
            proxySubmitter: null,
            resourceLinkLookupUuid: null,
            score: 60,
            state: 'submitted',
            sticker: null,
            submissionDraft: null,
            submissionStatus: 'unsubmitted',
            submissionType: null,
            submittedAt: '2025-05-29T10:00:00Z',
            turnitinData: null,
            feedbackForCurrentAttempt: false,
            unreadCommentCount: 0,
            url: null,
            assignedAssessments: [],
            assignmentId: '1',
            userId: '1',
            ...submissionOverrides,
          },
          assignment: {
            _id: '1',
            id: '1',
            allowedAttempts: null,
            allowedExtensions: [],
            assignmentGroup: {
              name: 'Assignments',
              _id: '1',
              id: '1',
              __typename: 'AssignmentGroup',
            },
            description: 'Test Assignment Description',
            dueAt: null,
            expectsSubmission: false,
            gradingType: 'points',
            gradeGroupStudentsIndividually: false,
            groupCategoryId: null,
            groupSet: null,
            lockAt: null,
            lockInfo: {
              isLocked: false,
              contextId: '1',
              assetString: 'assignment_1',
              __typename: 'LockInfo',
            },
            modules: [],
            name: 'Test Assignment',
            nonDigitalSubmission: false,
            originalityReportVisibility: 'immediate',
            pointsPossible: 60,
            submissionTypes: ['external_tool'],
            unlockAt: null,
            rubricSelfAssessmentEnabled: false,
            __typename: 'Assignment',
            rubric: null,
            ...assignmentOverrides,
          },
        },
      },
    },
  ]

  const renderWithContext = (submissionOverrides = {}, assignmentOverrides = {}) => {
    return renderHook(() => useSubmissionWorkflow('1', '2'), {
      wrapper: ({children}: {children: React.ReactNode}) => (
        <MockedProvider
          cache={createCache()}
          mocks={createMock(submissionOverrides, assignmentOverrides)}
        >
          {withSubmissionContext(children)}
        </MockedProvider>
      ),
    })
  }

  it('returns loading state initially', () => {
    const {result} = renderWithContext()
    expect(result.current.loading).toBe(true)
    expect(result.current.currentState).toBe(null)
  })

  it('returns submitted state for submitted submissions', async () => {
    const {result} = renderWithContext()

    // First wait for data to load
    await waitFor(() => {
      expect(result.current.loading).toBe(false)
      expect(result.current.currentState).toBeTruthy()
    })

    // Then check the state values
    const state = result.current.currentState
    expect(state?.value).toBe(2) // SUBMITTED state value
    expect(state?.subtitle).toBe('NEXT UP: Review Feedback')
    expect(typeof state?.title).toBe('function') // submitted state has a function title
  })

  it('returns completed state for graded submissions', async () => {
    const {result} = renderWithContext({
      state: 'graded',
      gradeHidden: false,
    })

    // First wait for data to load
    await waitFor(() => {
      expect(result.current.loading).toBe(false)
      expect(result.current.currentState).toBeTruthy()
    })

    // Then check the state values
    const state = result.current.currentState
    expect(state?.value).toBe(3) // COMPLETED state value
    expect(typeof state?.subtitle).toBe('function') // completed state has a function subtitle
    expect(state?.title).toBeDefined()
  })

  it('returns in progress state for not submitted submissions', async () => {
    const {result} = renderWithContext({
      state: 'unsubmitted',
      submittedAt: null,
    })

    // First wait for data to load
    await waitFor(() => {
      expect(result.current.loading).toBe(false)
      expect(result.current.currentState).toBeTruthy()
    })

    // Then check the state values
    const state = result.current.currentState
    expect(state?.value).toBe(1) // IN_PROGRESS state value
    expect(state?.subtitle).toBe('NEXT UP: Submit Assignment')
    expect(state?.title).toBeTruthy()
  })
})

/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {MockedResponse} from '@apollo/react-testing'
import {GRADEBOOK_QUERY, GRADEBOOK_STUDENT_QUERY} from '../../../queries/Queries'
import {type GradebookOptions, GradebookSortOrder} from '../../../types'

export const DEFAULT_ENV = {
  active_grading_periods: [],
  context_id: '1',
  context_url: '/courses/1',
  userId: '10',
  course_settings: {},
}

export const setGradebookOptions = (gradebookOptions = {}) => {
  const env = {GRADEBOOK_OPTIONS: {...DEFAULT_ENV, ...gradebookOptions}}
  return env
}

const GRADEBOOK_QUERY_MOCK_RESPONSE = {
  data: {
    course: {
      assignmentGroupsConnection: {
        nodes: [
          {
            id: '1',
            name: 'Assignments',
            state: 'available',
            position: 1,
            assignmentsConnection: {
              nodes: [
                {
                  id: '1',
                  name: 'Missing Assignment 1',
                  pointsPossible: 100,
                  assignmentGroupId: '1',
                  gradingType: 'points',
                },
                {
                  id: '2',
                  name: 'Missing Assignment 2',
                  pointsPossible: 100,
                  assignmentGroupId: '1',
                  gradingType: 'points',
                },
              ],
            },
            rules: {
              dropLowest: 1,
              dropHighest: null,
              neverDrop: null,
            },
          },
        ],
      },
      enrollmentsConnection: {
        nodes: [
          {
            user: {
              id: '5',
              name: 'Test User 1',
              sortableName: 'User 1, Test',
            },
            course_section_id: '1',
            state: 'active',
          },
        ],
      },
      submissionsConnection: {
        nodes: [
          {
            grade: '68',
            id: '13',
            score: 68.0,
            assignmentId: '1',
            redoRequest: false,
            submittedAt: '2023-06-01T00:19:23-06:00',
            userId: '5',
            state: 'submitted',
            gradingPeriodId: '1',
          },
          {
            grade: '2',
            id: '14',
            score: 2.0,
            assignmentId: '2',
            redoRequest: false,
            submittedAt: '2023-06-02T00:19:23-06:00',
            userId: '5',
            state: 'submitted',
            gradingPeriodId: '1',
          },
        ],
      },
      sectionsConnection: {
        nodes: [],
      },
    },
  },
}

const GRADEBOOK_STUDENT_QUERY_MOCK_RESPONSE = {
  data: {
    course: {
      usersConnection: {
        nodes: [
          {
            enrollments: [
              {
                id: '7',
                grades: {
                  unpostedCurrentGrade: 'D-',
                  unpostedCurrentScore: 61.0,
                  unpostedFinalGrade: 'F',
                  unpostedFinalScore: 58.1,
                },
                section: {
                  id: '2',
                  name: 'English',
                },
              },
            ],
            id: '5',
            loginId: 'rohanchugh',
            name: 'Rohan Chugh',
          },
        ],
      },
      submissionsConnection: {
        nodes: [
          {
            grade: '68',
            id: '13',
            score: 68.0,
            enteredScore: 68.0,
            assignmentId: '1',
            submissionType: 'online_text_entry',
            submittedAt: '2023-06-01T00:19:23-06:00',
            state: 'submitted',
            proxySubmitter: null,
            excused: false,
            late: true,
            latePolicyStatus: null,
            missing: false,
            userId: '5',
            cachedDueDate: '2023-05-12T23:59:59-06:00',
            gradingPeriodId: '1',
            deductedPoints: null,
            enteredGrade: '68%',
            gradeMatchesCurrentSubmission: true,
            customGradeStatus: null,
          },
          {
            grade: '2',
            id: '14',
            score: 2.0,
            enteredScore: 2.0,
            assignmentId: '2',
            submissionType: 'online_text_entry',
            submittedAt: '2023-06-02T00:19:23-06:00',
            state: 'submitted',
            proxySubmitter: null,
            excused: false,
            late: true,
            latePolicyStatus: null,
            missing: false,
            userId: '5',
            cachedDueDate: '2023-05-13T23:59:59-06:00',
            gradingPeriodId: '1',
            deductedPoints: null,
            enteredGrade: '2%',
            gradeMatchesCurrentSubmission: true,
            customGradeStatus: null,
          },
        ],
      },
    },
  },
}

export const setupGraphqlMocks = (overrides: MockedResponse[] = []): MockedResponse[] => {
  return [
    {
      request: {
        query: GRADEBOOK_QUERY,
        variables: {courseId: '1'},
      },
      result: GRADEBOOK_QUERY_MOCK_RESPONSE,
    },
    {
      request: {
        query: GRADEBOOK_STUDENT_QUERY,
        variables: {
          courseId: '1',
          userIds: '5',
        },
      },
      result: GRADEBOOK_STUDENT_QUERY_MOCK_RESPONSE,
    },
    ...overrides,
  ]
}

export const defaultGradebookOptions: GradebookOptions = {
  contextUrl: '/courses/1',
  sortOrder: GradebookSortOrder.Alphabetical,
  changeGradeUrl: 'testUrl',
  customOptions: {
    includeUngradedAssignments: false,
    hideStudentNames: false,
    showConcludedEnrollments: false,
    showNotesColumn: false,
    showTotalGradeAsPoints: false,
    allowFinalGradeOverride: false,
  },
  gradingStandardScalingFactor: 1,
  gradingStandardPointsBased: false,
  proxySubmissionEnabled: false,
}

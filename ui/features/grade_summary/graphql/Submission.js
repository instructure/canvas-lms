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

import {gql} from '@apollo/client'
import {arrayOf, float, string, bool, object} from 'prop-types'

import {RubricAssessment} from '@canvas/assignments/graphql/student/RubricAssessment'
import {SubmissionComment} from './SubmissionComment'
import {LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT} from '@canvas/lti-asset-processor/shared-with-sg/replicated/queries/getLtiAssetReports'

export const Submission = {
  fragment: gql`
    fragment Submission on Submission {
      _id
      autoGradeResultPresent
      customGradeStatus
      gradingStatus
      grade
      score
      gradingPeriodId
      hasUnreadRubricAssessment
      hideGradeFromStudent
      readState
      late
      updatedAt
      excused
      studentEnteredScore
      state
      submissionType
      commentsConnection {
        nodes {
          ...SubmissionComment
        }
      }
      rubricAssessmentsConnection {
        nodes {
          ...RubricAssessment
        }
      }
      ltiAssetReportsConnection(first: 10, latest: true) {
        nodes {
          ...LtiAssetReportForStudent
        }
      }
    }
    ${RubricAssessment.fragment}
    ${SubmissionComment.fragment}
    ${LTI_ASSET_REPORT_FOR_STUDENT_FRAGMENT}
  `,
  shape: {
    _id: string,
    autoGradeResultPresent: bool,
    customGradeStatus: string,
    gradingStatus: string,
    grade: string,
    score: float,
    gradingPeriodId: string,
    hasUnreadRubricAssessment: bool,
    hideGradeFromStudent: bool,
    readState: string,
    late: bool,
    updatedAt: string,
    excused: bool,
    studentEnteredScore: string,
    state: string,
    submissionType: string,
    commentsConnection: arrayOf({
      nodes: arrayOf({
        comment: string,
        createdAt: string,
        author: {
          name: string,
          shortName: string,
        },
      }),
    }),
    rubricAssessmentsConnection: {nods: arrayOf(RubricAssessment.shape)},
    ltiAssetReportsConnection: {
      // Lti Asset Processor types use Zod schemas, so there's not really a
      // need to replicate the full shape here.
      nodes: arrayOf(object),
    },
  },
  mock: ({
    _id = '1',
    autoGradeResultPresent = false,
    customGradeStatus = null,
    gradingStatus = 'graded',
    grade = 'A-',
    score = 90,
    gradingPeriodId = '1',
    hasUnreadRubricAssessment = false,
    hideGradeFromStudent = false,
    readState = 'read',
    late = false,
    updatedAt = '2019-01-01T00:00:00Z',
    excused = false,
    studentEnteredScore = '8',
    state = 'graded',
    submittedAt = null,
    submissionType = 'online_text_entry',
    commentsConnection = {
      nodes: [
        {
          comment: 'Great job!',
          createdAt: '2019-01-01T00:00:00Z',
          author: {
            name: 'John Doe',
            shortName: 'JD',
          },
        },
      ],
    },
    rubricAssessmentsConnection = {
      nodes: [RubricAssessment.mock()],
    },
    ltiAssetReportsConnection = {
      nodes: [],
    },
  } = {}) => ({
    _id,
    autoGradeResultPresent,
    customGradeStatus,
    gradingStatus,
    grade,
    score,
    gradingPeriodId,
    hasUnreadRubricAssessment,
    hideGradeFromStudent,
    readState,
    late,
    updatedAt,
    excused,
    studentEnteredScore,
    state,
    submittedAt,
    submissionType,
    commentsConnection,
    rubricAssessmentsConnection,
    ltiAssetReportsConnection,
  }),
}

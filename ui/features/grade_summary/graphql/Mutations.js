/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Error} from '../../../shared/graphql/Error'
import {Submission} from './Submission'
import gql from 'graphql-tag'

export const UPDATE_SUBMISSIONS_READ_STATE = gql`
  mutation UpdateSubmissionsReadState($submissionIds: [ID!]!, $read: Boolean!) {
    updateSubmissionsReadState(input: {submissionIds: $submissionIds, read: $read}) {
      submissions {
        _id
        readState
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
`

export const UPDATE_RUBRIC_ASSESSMENT_READ_STATE = gql`
  mutation UpdateRubricAssessmentReadState($submissionIds: [ID!]!) {
    updateRubricAssessmentReadState(input: {submissionIds: $submissionIds}) {
      submissions {
        _id
        hasUnreadRubricAssessment
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
`

export const UPDATE_SUBMISSION_STUDENT_ENTERED_SCORE = gql`
  mutation UpdateSubmissionStudentEnteredScore(
    $submissionId: ID!
    $enteredScore: Float!
    $courseID: ID!
  ) {
    updateSubmissionStudentEnteredScore(
      input: {submissionId: $submissionId, enteredScore: $enteredScore}
    ) {
      submission {
        ...Submission
      }
    }
  }
  ${Submission.fragment}
`

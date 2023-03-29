/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import gql from 'graphql-tag'

import {Assignment} from './Assignment'
import {ExternalTool} from './ExternalTool'
import {ProficiencyRating} from './ProficiencyRating'
import {Rubric} from './Rubric'
import {RubricAssessment} from './RubricAssessment'
import {RubricAssociation} from './RubricAssociation'
import {Submission} from './Submission'
import {SubmissionComment} from './SubmissionComment'
import {SubmissionHistory} from './SubmissionHistory'
import {UserGroups} from './UserGroups'

export const EXTERNAL_TOOLS_QUERY = gql`
  query ExternalTools($courseID: ID!) {
    course(id: $courseID) {
      externalToolsConnection(filter: {placement: homework_submission}) {
        nodes {
          ...ExternalTool
        }
      }
    }
  }
  ${ExternalTool.fragment}
`

export const RUBRIC_QUERY = gql`
  query GetRubric(
    $assignmentLid: ID!
    $submissionID: ID!
    $courseID: ID!
    $submissionAttempt: Int!
  ) {
    assignment: legacyNode(_id: $assignmentLid, type: Assignment) {
      ... on Assignment {
        rubric {
          ...Rubric
        }
        rubricAssociation {
          ...RubricAssociation
        }
      }
    }
    submission(id: $submissionID) {
      id
      rubricAssessmentsConnection(filter: {forAttempt: $submissionAttempt}) {
        nodes {
          ...RubricAssessment
        }
      }
    }
    course(id: $courseID) {
      account {
        outcomeProficiency {
          proficiencyRatingsConnection {
            nodes {
              ...ProficiencyRating
            }
          }
        }
      }
    }
  }
  ${Rubric.fragment}
  ${RubricAssessment.fragment}
  ${RubricAssociation.fragment}
  ${ProficiencyRating.fragment}
`

export const STUDENT_VIEW_QUERY = gql`
  query GetAssignment($assignmentLid: ID!, $submissionID: ID!) {
    assignment(id: $assignmentLid) {
      ...Assignment
      rubric {
        ...Rubric
      }
    }
    submission(id: $submissionID) {
      ...Submission
    }
  }
  ${Assignment.fragment}
  ${Rubric.fragment}
  ${Submission.fragment}
`

export const STUDENT_VIEW_QUERY_WITH_REVIEWER_SUBMISSION = gql`
  query GetAssignment($assignmentLid: ID!, $submissionID: ID!, $reviewerSubmissionID: ID!) {
    assignment(id: $assignmentLid) {
      ...Assignment
      rubric {
        ...Rubric
      }
    }
    submission(id: $submissionID) {
      ...Submission
    }
    reviewerSubmission: submission(id: $reviewerSubmissionID) {
      ...Submission
    }
  }
  ${Assignment.fragment}
  ${Rubric.fragment}
  ${Submission.fragment}
`

export const LOGGED_OUT_STUDENT_VIEW_QUERY = gql`
  query GetAssignment($assignmentLid: ID!) {
    assignment(id: $assignmentLid) {
      ...Assignment
      rubric {
        ...Rubric
      }
    }
  }
  ${Assignment.fragment}
  ${Rubric.fragment}
`

export const SUBMISSION_COMMENT_QUERY = gql`
  query GetSubmissionComments(
    $submissionId: ID!
    $submissionAttempt: Int!
    $cursor: String
    $peerReview: Boolean = false
  ) {
    submissionComments: node(id: $submissionId) {
      ... on Submission {
        commentsConnection(
          last: 20
          before: $cursor
          filter: {forAttempt: $submissionAttempt, peerReview: $peerReview}
        ) {
          pageInfo {
            startCursor
            hasPreviousPage
          }
          nodes {
            ...SubmissionComment
          }
        }
      }
    }
  }
  ${SubmissionComment.fragment}
`

export const SUBMISSION_HISTORIES_QUERY = gql`
  query NextSubmission($submissionID: ID!) {
    node(id: $submissionID) {
      ... on Submission {
        submissionHistoriesConnection(filter: {includeCurrentSubmission: false}) {
          nodes {
            ...SubmissionHistory
          }
        }
      }
    }
  }
  ${SubmissionHistory.fragment}
`

export const USER_GROUPS_QUERY = gql`
  query GetUserGroups($userID: ID!) {
    legacyNode(_id: $userID, type: User) {
      ...UserGroups
    }
  }
  ${UserGroups.fragment}
`

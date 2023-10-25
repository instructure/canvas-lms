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

import gql from 'graphql-tag'

import {AssignmentGroup} from './AssignmentGroup'
import {Assignment} from './Assignment'
import {GradingStandard} from './GradingStandard'
import {GradingPeriod} from './GradingPeriod'
import {GradingPeriodGroup} from './GradingPeriodGroup'
import {Submission} from './Submission'

export const ASSIGNMENTS = gql`
  query GetAssignments($courseID: ID!, $gradingPeriodID: ID, $studentId: ID) {
    legacyNode(_id: $courseID, type: Course) {
      ... on Course {
        id
        name
        applyGroupWeights
        assignmentsConnection(filter: {gradingPeriodId: $gradingPeriodID, userId: $studentId}) {
          nodes {
            ...Assignment
            submissionsConnection(filter: {userId: $studentId, includeUnsubmitted: true}) {
              nodes {
                ...Submission
              }
            }
          }
        }
        assignmentGroupsConnection {
          nodes {
            ...AssignmentGroup
          }
        }
        gradingStandard {
          ...GradingStandard
        }
        gradingPeriodsConnection {
          nodes {
            ...GradingPeriod
          }
        }
        relevantGradingPeriodGroup {
          ...GradingPeriodGroup
        }
      }
    }
  }
  ${AssignmentGroup.fragment}
  ${Assignment.fragment}
  ${GradingStandard.fragment}
  ${GradingPeriod.fragment}
  ${GradingPeriodGroup.fragment}
  ${Submission.fragment}
`

/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {executeQuery} from '@canvas/query/graphql'

export const ASSIGNMENT_RUBRIC_ASSESSMENTS_QUERY = gql`
  query GetAssignmentRubricAssessments($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      _id
      rubricAssessment {
        assessmentsCount
      }
    }
  }
`

export type FetchRequestParams = {
  queryKey: (string | number)[]
}

export type RubricAssessmentsResponse = {
  assignment: {
    _id: string
    rubricAssessment: {
      assessmentsCount: number
    }
  }
}

const ASSIGNMENT_ID_INDEX = 1

export const fetchAssignmentRubricAssessments = async ({queryKey}: FetchRequestParams) =>
  executeQuery<RubricAssessmentsResponse>(ASSIGNMENT_RUBRIC_ASSESSMENTS_QUERY, {
    assignmentId: queryKey[ASSIGNMENT_ID_INDEX],
  })

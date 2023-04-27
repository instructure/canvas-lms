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

import {camelizeProperties} from '@canvas/convert-case'
import {createClient, gql} from '@canvas/apollo'
import resolveProgress from '@canvas/progress/resolve_progress'

export const POST_ASSIGNMENT_GRADES = gql`
  mutation ($assignmentId: ID!, $gradedOnly: Boolean) {
    postAssignmentGrades(input: {assignmentId: $assignmentId, gradedOnly: $gradedOnly}) {
      progress {
        _id
        state
      }
    }
  }
`

export const POST_ASSIGNMENT_GRADES_FOR_SECTIONS = gql`
  mutation ($assignmentId: ID!, $sectionIds: [ID!]!, $gradedOnly: Boolean) {
    postAssignmentGradesForSections(
      input: {assignmentId: $assignmentId, sectionIds: $sectionIds, gradedOnly: $gradedOnly}
    ) {
      progress {
        _id
        state
      }
    }
  }
`

export function postAssignmentGrades(assignmentId, options = {}) {
  return createClient()
    .mutate({
      mutation: POST_ASSIGNMENT_GRADES,
      variables: {assignmentId, gradedOnly: !!options.gradedOnly},
    })
    .then(({data}) => ({
      id: data.postAssignmentGrades.progress._id,
      workflowState: data.postAssignmentGrades.progress.state,
    }))
}

export function postAssignmentGradesForSections(assignmentId, sectionIds = [], options = {}) {
  return createClient()
    .mutate({
      mutation: POST_ASSIGNMENT_GRADES_FOR_SECTIONS,
      variables: {assignmentId, sectionIds, gradedOnly: !!options.gradedOnly},
    })
    .then(({data}) => ({
      id: data.postAssignmentGradesForSections.progress._id,
      workflowState: data.postAssignmentGradesForSections.progress.state,
    }))
}

export function resolvePostAssignmentGradesStatus(progress) {
  return resolveProgress({
    url: `/api/v1/progress/${progress.id}`,
    workflow_state: progress.workflowState,
  }).then(results => camelizeProperties(results))
}

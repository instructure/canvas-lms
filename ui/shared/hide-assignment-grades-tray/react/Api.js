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

export const HIDE_ASSIGNMENT_GRADES = gql`
  mutation ($assignmentId: ID!) {
    hideAssignmentGrades(input: {assignmentId: $assignmentId}) {
      progress {
        _id
        state
      }
    }
  }
`

export const HIDE_ASSIGNMENT_GRADES_FOR_SECTIONS = gql`
  mutation ($assignmentId: ID!, $sectionIds: [ID!]!) {
    hideAssignmentGradesForSections(input: {assignmentId: $assignmentId, sectionIds: $sectionIds}) {
      progress {
        _id
        state
      }
    }
  }
`

export function hideAssignmentGrades(assignmentId) {
  return createClient()
    .mutate({
      mutation: HIDE_ASSIGNMENT_GRADES,
      variables: {assignmentId},
    })
    .then(({data}) => ({
      id: data.hideAssignmentGrades.progress._id,
      workflowState: data.hideAssignmentGrades.progress.state,
    }))
}

export function hideAssignmentGradesForSections(assignmentId, sectionIds = []) {
  return createClient()
    .mutate({
      mutation: HIDE_ASSIGNMENT_GRADES_FOR_SECTIONS,
      variables: {assignmentId, sectionIds},
    })
    .then(({data}) => ({
      id: data.hideAssignmentGradesForSections.progress._id,
      workflowState: data.hideAssignmentGradesForSections.progress.state,
    }))
}

export function resolveHideAssignmentGradesStatus(progress) {
  return resolveProgress({
    url: `/api/v1/progress/${progress.id}`,
    workflow_state: progress.workflowState,
  }).then(results => camelizeProperties(results))
}

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

import {AssignmentConnection, AssignmentGroupConnection} from '../types'
import {AssignmentGroupCriteriaMap} from '../../../shared/grading/grading.d'

export function mapAssignmentGroupQueryResults(assignmentGroup: AssignmentGroupConnection[]): {
  mappedAssignments: AssignmentConnection[]
  mappedAssignmentGroupMap: AssignmentGroupCriteriaMap
} {
  return assignmentGroup.reduce(
    (prev, curr) => {
      prev.mappedAssignments.push(...curr.assignmentsConnection.nodes)

      prev.mappedAssignmentGroupMap[curr.id] = {
        name: curr.name,
        assignments: curr.assignmentsConnection.nodes.map(assignment => {
          return {
            id: assignment.id,
            name: assignment.name,
            points_possible: assignment.pointsPossible,
            submission_types: assignment.submissionTypes,
            anonymize_students: assignment.anonymizeStudents,
            omit_from_final_grade: assignment.omitFromFinalGrade,
            workflow_state: assignment.workflowState,
          }
        }),
        group_weight: curr.groupWeight,
        rules: curr.rules,
        id: curr.id,
        position: curr.position,
        integration_data: {}, // TODO: Get Data
        sis_source_id: null, // TODO: Get data
      }

      return prev
    },
    {
      mappedAssignments: [] as AssignmentConnection[],
      mappedAssignmentGroupMap: {} as AssignmentGroupCriteriaMap,
    }
  )
}

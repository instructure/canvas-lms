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

import {useQuery} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {AssignmentRubric} from '../queries'
import type {RubricAssociation} from '../../types/rubric'

export type UseAssignmentRubricResult = {
  rubric?: AssignmentRubric
  rubricAssociation?: RubricAssociation
}

/**
 * Hook to fetch rubric data for an assignment
 *
 * This hook calls the Canvas API endpoint that returns the rubric and rubric association
 * for a specific assignment. The endpoint returns the complete rubric model ready for
 * initializing the RubricAssignmentContainer component.
 */
type RubricDataResponse = {
  assigned_rubric?: AssignmentRubric
  rubric_association?: RubricAssociation
}

export function useAssignmentRubric(courseId: string, assignmentId: string) {
  return useQuery<UseAssignmentRubricResult, Error>({
    queryKey: ['assignment-rubric', courseId, assignmentId],
    queryFn: async () => {
      const {json} = await doFetchApi<RubricDataResponse>({
        path: `/courses/${courseId}/assignments/${assignmentId}/rubric_data`,
      })

      if (!json) {
        throw new Error('Failed to fetch rubric data: response is undefined')
      }

      return {
        rubric: json.assigned_rubric,
        rubricAssociation: json.rubric_association,
      }
    },
    enabled: !!courseId && !!assignmentId,
    staleTime: 5 * 60 * 1000,
  })
}

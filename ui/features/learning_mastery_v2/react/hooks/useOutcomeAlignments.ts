/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export interface OutcomeAlignment {
  id?: number
  learning_outcome_id?: number
  assignment_id?: number | null
  assessment_id?: number | null
  submission_types?: string
  url?: string
  title?: string
}

interface UseOutcomeAlignmentsProps {
  courseId: string
  studentId?: string
  assignmentId?: string
  enabled?: boolean
}

export const useOutcomeAlignments = ({
  courseId,
  studentId,
  assignmentId,
  enabled = true,
}: UseOutcomeAlignmentsProps) => {
  return useQuery({
    queryKey: ['outcomeAlignments', courseId, studentId, assignmentId],
    queryFn: async (): Promise<OutcomeAlignment[]> => {
      const params = new URLSearchParams()

      if (studentId) {
        params.append('student_id', studentId)
      }

      if (assignmentId) {
        params.append('assignment_id', assignmentId)
      }

      const queryString = params.toString()
      const path = `/api/v1/courses/${courseId}/outcome_alignments${queryString ? `?${queryString}` : ''}`

      const {json} = await doFetchApi({
        path,
        method: 'GET',
      })

      return json as OutcomeAlignment[]
    },
    enabled: enabled && !!courseId && (!!studentId || !!assignmentId),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

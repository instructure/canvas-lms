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

export interface Section {
  id: number
  name: string
}

export interface LmgbUserDetails {
  course: {
    name: string
  }
  user: {
    sections: Section[]
    last_login: string | null
  }
}

interface UseLmgbUserDetailsProps {
  courseId: string
  studentId: string
  enabled?: boolean
}

export const useLmgbUserDetails = ({
  courseId,
  studentId,
  enabled = true,
}: UseLmgbUserDetailsProps) => {
  return useQuery({
    queryKey: ['lmgbUserDetails', courseId, studentId],
    queryFn: async (): Promise<LmgbUserDetails> => {
      const {json} = await doFetchApi({
        path: `/api/v1/courses/${courseId}/users/${studentId}/lmgb_user_details`,
        method: 'GET',
      })

      return json as LmgbUserDetails
    },
    enabled: enabled && !!courseId && !!studentId,
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

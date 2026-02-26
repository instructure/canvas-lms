/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

interface AllocationConversionItem {
  id: number
  [key: string]: unknown
}

async function fetchAllocationConversion(
  courseId: string,
  assignmentId: string,
): Promise<AllocationConversionItem[]> {
  const {json} = await doFetchApi<AllocationConversionItem[]>({
    path: `/api/v1/courses/${courseId}/assignments/${assignmentId}/check_allocation_conversion`,
  })
  return json || []
}

export const useCheckAllocationConversion = (
  courseId: string,
  assignmentId: string,
  enabled: boolean,
) => {
  const {data, isLoading, error} = useQuery<AllocationConversionItem[], Error>({
    queryKey: ['checkAllocationConversion', courseId, assignmentId],
    queryFn: () => fetchAllocationConversion(courseId, assignmentId),
    enabled: !!courseId && !!assignmentId && enabled,
    staleTime: 5 * 60 * 1000,
  })

  return {
    hasLegacyAllocations: Array.isArray(data) && data.length > 0,
    loading: isLoading,
    error,
  }
}

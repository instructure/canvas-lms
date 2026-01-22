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
import {loadMasteryDistribution} from '@canvas/outcomes/react/apiClient'
import {MasteryDistributionResponse} from '@canvas/outcomes/react/types/mastery_distribution'

export interface UseMasteryDistributionOptions {
  courseId: string
  filters: string[]
  outcomeIds?: string[]
  studentIds?: string[]
  includeAlignments?: boolean
  onlyAssignmentAlignments?: boolean
  showUnpublishedAssignments?: boolean
  enabled?: boolean
}

export const useMasteryDistribution = ({
  courseId,
  filters,
  outcomeIds,
  studentIds,
  includeAlignments = false,
  onlyAssignmentAlignments = false,
  showUnpublishedAssignments = false,
  enabled = true,
}: UseMasteryDistributionOptions) => {
  return useQuery<MasteryDistributionResponse>({
    queryKey: [
      'masteryDistribution',
      courseId,
      filters,
      outcomeIds,
      studentIds,
      includeAlignments,
      onlyAssignmentAlignments,
      showUnpublishedAssignments,
    ],
    queryFn: () =>
      loadMasteryDistribution(
        courseId,
        filters,
        outcomeIds,
        studentIds,
        includeAlignments,
        onlyAssignmentAlignments,
        showUnpublishedAssignments,
      ),
    enabled,
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

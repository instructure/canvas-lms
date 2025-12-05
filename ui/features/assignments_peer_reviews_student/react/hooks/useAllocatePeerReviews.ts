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

import {useMutation, useQueryClient} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignments_peer_reviews_student')

interface AllocatePeerReviewsParams {
  courseId: string
  assignmentId: string
}

export function useAllocatePeerReviews() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async ({courseId, assignmentId}: AllocatePeerReviewsParams) => {
      await doFetchApi({
        path: `/api/v1/courses/${courseId}/assignments/${assignmentId}/allocate`,
        method: 'POST',
      })
    },
    onSuccess: (_data, variables) => {
      // Invalidate the assignment query to refetch updated assessment requests
      queryClient.invalidateQueries({queryKey: ['peerReviewAssignment', variables.assignmentId]})
    },
    onError: () => showFlashError(I18n.t('Failed to allocate peer reviews'))(),
  })
}

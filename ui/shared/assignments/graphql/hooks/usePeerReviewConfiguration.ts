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
import {executeQuery} from '@canvas/graphql'
import {
  PeerReviewConfigurationData,
  PeerReviewConfiguration,
  PeerReviewSubAssignment,
} from '../teacher/AssignmentTeacherTypes'
import {PEER_REVIEW_CONFIGURATION_QUERY} from '../teacher/Queries'

async function getPeerReviewConfiguration(assignmentId: string): Promise<{
  hasGroupCategory: boolean
  peerReviews: PeerReviewConfiguration | null
  peerReviewSubAssignment: PeerReviewSubAssignment | null
}> {
  const result = await executeQuery<PeerReviewConfigurationData>(PEER_REVIEW_CONFIGURATION_QUERY, {
    assignmentId,
  })

  return {
    hasGroupCategory: result.assignment?.hasGroupCategory || false,
    peerReviews: result.assignment?.peerReviews || null,
    peerReviewSubAssignment: result.assignment?.peerReviewSubAssignment || null,
  }
}

export const usePeerReviewConfiguration = (assignmentId: string) => {
  const peerReviewConfigQuery = useQuery<
    {
      hasGroupCategory: boolean
      peerReviews: PeerReviewConfiguration | null
      peerReviewSubAssignment: PeerReviewSubAssignment | null
    },
    Error
  >({
    queryKey: ['peerReviewConfiguration', assignmentId],
    queryFn: () => getPeerReviewConfiguration(assignmentId),
    enabled: !!assignmentId,
    networkMode: 'always',
  })

  return {
    hasGroupCategory: peerReviewConfigQuery.data?.hasGroupCategory || false,
    peerReviews: peerReviewConfigQuery.data?.peerReviews || null,
    peerReviewSubAssignment: peerReviewConfigQuery.data?.peerReviewSubAssignment || null,
    loading: peerReviewConfigQuery.isLoading,
    error: peerReviewConfigQuery.error,
  }
}

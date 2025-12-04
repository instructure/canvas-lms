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
import {SEARCH_GROUP_OUTCOMES} from '@canvas/outcomes/graphql/Management'
import doFetchApi from '@canvas/do-fetch-api-effect'

interface RootOutcomeGroup {
  id: number
  title: string
  vendor_guid: string | null
  url: string
  subgroups_url: string
  outcomes_url: string
  can_edit: boolean
  import_url: string
  context_id: number
  context_type: string
}

interface Rating {
  description: string
  points: number
}

interface FriendlyDescription {
  _id: string
  description: string
}

interface OutcomeNode {
  _id: string
  description: string
  title: string
  displayName: string
  calculationMethod: string
  calculationInt: number
  masteryPoints: number
  ratings: Rating[]
  canEdit: boolean
  canArchive: boolean
  contextType: string
  contextId: string
  friendlyDescription: FriendlyDescription | null
}

interface OutcomeEdge {
  canUnlink: boolean
  _id: string
  node: OutcomeNode
  group: {
    _id: string
    title: string
  }
}

interface PageInfo {
  hasNextPage: boolean
  endCursor: string | null
}

interface OutcomesData {
  group: {
    _id: string
    description: string
    title: string
    outcomesCount: number
    notImportedOutcomesCount: number
    outcomes: {
      pageInfo: PageInfo
      edges: OutcomeEdge[]
    }
  }
}

interface UseOutcomesProps {
  courseId: string
  groupId?: string
  searchTerm?: string
  enabled?: boolean
}

interface UseOutcomesReturn {
  outcomes: OutcomeEdge[]
  outcomesCount: number
  isLoading: boolean
  error: Error | null
  hasNextPage: boolean
  endCursor: string | null
}

async function fetchRootOutcomeGroup(courseId: string): Promise<RootOutcomeGroup> {
  const {json} = await doFetchApi({
    path: `/api/v1/courses/${courseId}/root_outcome_group`,
    method: 'GET',
  })

  return json as RootOutcomeGroup
}

async function fetchOutcomes(
  groupId: string,
  courseId: string,
  searchQuery?: string,
): Promise<OutcomesData> {
  const params = {
    id: groupId,
    outcomesContextId: courseId,
    outcomesContextType: 'Course',
  }

  if (searchQuery) {
    Object.assign(params, {searchQuery})
  }

  return await executeQuery<OutcomesData>(SEARCH_GROUP_OUTCOMES, params)
}

export const useOutcomes = ({
  courseId,
  groupId: providedGroupId,
  searchTerm = '',
  enabled = true,
}: UseOutcomesProps): UseOutcomesReturn => {
  const trimmedSearchTerm = searchTerm.trim()
  const finalSearchTerm = trimmedSearchTerm || undefined

  // Fetch root outcome group if groupId is not provided
  const rootOutcomeGroupQuery = useQuery<RootOutcomeGroup, Error>({
    queryKey: ['rootOutcomeGroup', courseId],
    queryFn: () => fetchRootOutcomeGroup(courseId),
    enabled: enabled && !!courseId && !providedGroupId,
  })

  const groupId = providedGroupId || rootOutcomeGroupQuery.data?.id.toString()

  const outcomesQuery = useQuery<OutcomesData, Error>({
    queryKey: ['outcomes', groupId, courseId, finalSearchTerm],
    queryFn: () => fetchOutcomes(groupId!, courseId, finalSearchTerm),
    enabled: enabled && !!courseId && !!groupId,
  })

  const isLoading = providedGroupId
    ? outcomesQuery.isLoading
    : rootOutcomeGroupQuery.isLoading || outcomesQuery.isLoading

  const error = rootOutcomeGroupQuery.error || outcomesQuery.error

  return {
    outcomes: outcomesQuery.data?.group?.outcomes?.edges || [],
    outcomesCount: outcomesQuery.data?.group?.outcomesCount || 0,
    isLoading,
    error,
    hasNextPage: outcomesQuery.data?.group?.outcomes?.pageInfo?.hasNextPage || false,
    endCursor: outcomesQuery.data?.group?.outcomes?.pageInfo?.endCursor || null,
  }
}

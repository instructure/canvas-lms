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

import {useQuery, useQueryClient, QueryClient} from '@tanstack/react-query'
import {executeQuery} from '@canvas/graphql'
import {useCallback} from 'react'
import {ALLOCATION_RULES_QUERY} from '../teacher/Queries'
import {
  AllocationRulesData,
  AllocationRuleType,
  GraphQLPageData,
  UseAllocationRulesResult,
} from '../teacher/AssignmentTeacherTypes'

async function fetchGraphQLPage(
  assignmentId: string,
  cursor: string | null = null,
  searchTerm: string = '',
): Promise<GraphQLPageData> {
  const result: AllocationRulesData = await executeQuery<AllocationRulesData>(
    ALLOCATION_RULES_QUERY,
    {
      assignmentId,
      after: cursor,
      searchTerm: searchTerm || undefined,
    },
  )

  const assignment = result.assignment
  if (!assignment || !assignment.allocationRules) {
    return {
      rules: [],
      hasNextPage: false,
      endCursor: null,
      totalCount: 0,
      requiredPeerReviewsCount: assignment?.peerReviews?.count || 0,
    }
  }

  const connection = assignment.allocationRules.rulesConnection
  if (!connection) {
    return {
      rules: [],
      hasNextPage: false,
      endCursor: null,
      totalCount: assignment.allocationRules.count || 0,
      requiredPeerReviewsCount: assignment.peerReviews?.count || 0,
    }
  }

  return {
    rules: connection.nodes,
    hasNextPage: connection.pageInfo.hasNextPage,
    endCursor: connection.pageInfo.endCursor,
    totalCount: assignment.allocationRules.count || 0,
    requiredPeerReviewsCount: assignment.peerReviews?.count || 0,
  }
}

const TOTAL_COUNT_CACHE_KEY = (assignmentId: string) => [
  'allocationRules',
  assignmentId,
  'totalCount',
]

async function getAllocationRulesPage(
  assignmentId: string,
  page: number,
  itemsPerPage: number,
  queryClient: QueryClient,
  searchTerm: string = '',
  forceRefresh: boolean = false,
): Promise<{
  rules: AllocationRuleType[]
  totalCount: number | null
  requiredPeerReviewsCount: number
}> {
  const graphQLPageSize = 20
  const startIndex = (page - 1) * itemsPerPage
  const endIndex = startIndex + itemsPerPage - 1

  const startGraphQLPage = Math.floor(startIndex / graphQLPageSize)
  const endGraphQLPage = Math.floor(endIndex / graphQLPageSize)

  const allRules: AllocationRuleType[] = []
  let totalCount: number | null = null
  let requiredPeerReviewsCount = 0
  let cursor: string | null = null

  const cachedTotalCount = queryClient.getQueryData<number | null>(
    TOTAL_COUNT_CACHE_KEY(assignmentId),
  )

  for (let i = 0; i <= endGraphQLPage; i++) {
    const queryKey = ['allocationRules', assignmentId, 'graphql-page', i, searchTerm]
    let pageData = queryClient.getQueryData<GraphQLPageData>(queryKey)

    if (!pageData || forceRefresh) {
      if (i > 0) {
        const prevPageKey = ['allocationRules', assignmentId, 'graphql-page', i - 1, searchTerm]
        const prevPageData = queryClient.getQueryData<GraphQLPageData>(prevPageKey)
        cursor = prevPageData?.endCursor || null
      }

      pageData = await queryClient.fetchQuery({
        queryKey,
        queryFn: () => fetchGraphQLPage(assignmentId, cursor, searchTerm),
        networkMode: 'always',
        staleTime: forceRefresh ? 0 : 5 * 60 * 1000,
      })
    }

    if (pageData) {
      if (pageData.requiredPeerReviewsCount !== undefined) {
        requiredPeerReviewsCount = pageData.requiredPeerReviewsCount
      }

      if (totalCount === null && pageData.totalCount !== null) {
        totalCount = pageData.totalCount
        queryClient.setQueryData(TOTAL_COUNT_CACHE_KEY(assignmentId), pageData.totalCount)
      }

      if (i >= startGraphQLPage) {
        allRules.push(...pageData.rules)
      }

      cursor = pageData.endCursor
      if (!pageData.hasNextPage) break
    }
  }

  if (totalCount === null && cachedTotalCount !== undefined) {
    totalCount = cachedTotalCount
  }

  const rulesStartIndex = startIndex - startGraphQLPage * graphQLPageSize
  const rulesEndIndex = rulesStartIndex + itemsPerPage
  const pageRules = allRules.slice(rulesStartIndex, rulesEndIndex)

  return {rules: pageRules, totalCount, requiredPeerReviewsCount}
}

export const useAllocationRules = (
  assignmentId: string,
  page: number = 1,
  itemsPerPage: number = 20,
  searchTerm: string = '',
): UseAllocationRulesResult => {
  const queryClient = useQueryClient()
  const trimmedSearchTerm = searchTerm.trim()
  const finalSearchTerm = trimmedSearchTerm || undefined

  const {data, isLoading, error} = useQuery<
    {rules: AllocationRuleType[]; totalCount: number | null; requiredPeerReviewsCount: number},
    Error
  >({
    queryKey: ['allocationRules', assignmentId, page, itemsPerPage, finalSearchTerm],
    queryFn: () =>
      getAllocationRulesPage(assignmentId, page, itemsPerPage, queryClient, finalSearchTerm),
    enabled: !!assignmentId,
    networkMode: 'always',
    staleTime: 5 * 60 * 1000,
  })

  const enhancedRefetch = useCallback(
    async (targetPage: number) => {
      queryClient.removeQueries({
        queryKey: ['allocationRules', assignmentId, 'graphql-page'],
        exact: false,
      })

      queryClient.removeQueries({
        queryKey: ['allocationRules', assignmentId],
        exact: false,
      })

      const result = await queryClient.fetchQuery({
        queryKey: ['allocationRules', assignmentId, targetPage, itemsPerPage],
        queryFn: () =>
          getAllocationRulesPage(
            assignmentId,
            targetPage,
            itemsPerPage,
            queryClient,
            finalSearchTerm,
            true,
          ),
        networkMode: 'always',
        staleTime: 0,
      })

      if (result.totalCount !== null) {
        queryClient.setQueryData(TOTAL_COUNT_CACHE_KEY(assignmentId), result.totalCount)
      }

      return result
    },
    [queryClient, assignmentId, itemsPerPage],
  )

  return {
    rules: data?.rules || [],
    totalCount: data?.totalCount || null,
    requiredPeerReviewsCount: data?.requiredPeerReviewsCount || 0,
    loading: isLoading,
    error,
    refetch: enhancedRefetch,
  }
}

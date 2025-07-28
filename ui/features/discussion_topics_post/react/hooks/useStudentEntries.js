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

import {useAllPages} from '@canvas/query'
import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('student_entries')

export const STUDENT_DISCUSSION_QUERY = gql`
  query GetDiscussionQuery(
    $discussionID: ID!
    $perPage: Int!
    $discussionPageAmount: Int!
    $userSearchId: String
    $cursor: String
  ) {
    legacyNode(_id: $discussionID, type: Discussion) {
      ... on Discussion {
        discussionEntriesConnection(userSearchId: $userSearchId, first: $perPage, after: $cursor) {
          nodes {
            _id
            rootEntryId
            rootEntryPageNumber(perPage: $discussionPageAmount)
          }
          pageInfo {
            endCursor
            hasNextPage
            hasPreviousPage
            startCursor
          }
        }
      }
    }
  }
`

async function getStudentEntries({queryKey, pageParam}) {
  // queryKey structure:
  // ['studentEntries', discussionID, perPage, discussionPageAmount, userSearchId]
  const [_key, discussionID, perPage, discussionPageAmount, userSearchId] = queryKey

  const cursor = pageParam || null

  try {
    const result = await executeQuery(STUDENT_DISCUSSION_QUERY, {
      discussionID,
      perPage,
      discussionPageAmount,
      userSearchId,
      cursor,
    })

    if (result.errors) {
      throw new Error(result.errors.map(err => err.message).join(', '))
    }

    const discussionEntriesConnection = result.legacyNode?.discussionEntriesConnection

    if (!discussionEntriesConnection) {
      return {
        entries: [],
        pageInfo: {hasNextPage: false, endCursor: null},
      }
    }

    const {nodes, pageInfo} = discussionEntriesConnection
    const entries = nodes || []

    return {
      entries,
      pageInfo: pageInfo || {hasNextPage: false, endCursor: null},
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    showFlashError(I18n.t('Failed to load student entries: %{error}', {error: errorMessage}))
    throw error
  }
}

export function useStudentEntries(
  discussionID,
  perPage = 50,
  discussionPageAmount = 50,
  userSearchId,
) {
  return useAllPages({
    queryKey: ['studentEntries', discussionID, perPage, discussionPageAmount, userSearchId],
    queryFn: getStudentEntries,
    getNextPageParam: lastPage =>
      lastPage.pageInfo.hasNextPage ? lastPage.pageInfo.endCursor : undefined,
    enabled: !!discussionID,
  })
}

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

import {useQuery} from '@canvas/query'
import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/query/graphql'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {ModuleItemsResponse, ModuleItemsGraphQLResult, ModuleItem} from '../../utils/types.d'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

const MODULE_ITEMS_QUERY = gql`
  query GetModuleItemsQuery($moduleId: ID!) {
    legacyNode(_id: $moduleId, type: Module) {
      ... on Module {
        moduleItems {
          _id
          id
          url
          indent
          content {
            ... on Assignment {
              _id
              id
              title
              type: __typename
              pointsPossible
              dueAt
              lockAt
              unlockAt
              published
              canUnpublish
            }
            ... on Discussion {
              _id
              id
              title
              type: __typename
              lockAt
              todoDate
              discussionType
              published
              canUnpublish
            }
            ... on File {
              _id
              id
              title: displayName
              type: __typename
              contentType
              size
              thumbnailUrl
              url
              published
              canUnpublish
            }
            ... on Page {
              _id
              id
              title
              published
              canUnpublish
              type: __typename
            }
            ... on Quiz {
              _id
              id
              title
              type: __typename
              pointsPossible
              published
              canUnpublish
            }
            ... on ExternalUrl {
              title
              type: __typename
              url
              published
              canUnpublish
            }
            ... on ModuleExternalTool {
              title
              type: __typename
              url
              published
              canUnpublish
            }
            ... on SubHeader {
              title
              type: __typename
            }
          }
        }
      }
    }
  }
`

const transformItems = (items: ModuleItem[], moduleId: string) => {
  return items.map((item, index) => ({
    ...item,
    moduleId,
    index,
    content: item.content ? {
      ...item.content,
      id: item.content.id || item._id,
      type: item.content.type || 'unknown',
    } : null
  }))
}

async function getModuleItems({queryKey}: {queryKey: any}): Promise<ModuleItemsResponse> {
  const [_key, moduleId] = queryKey
  try {
    const result = await executeQuery<ModuleItemsGraphQLResult>(MODULE_ITEMS_QUERY, {
      moduleId,
    })

    if (result.errors) {
      throw new Error(result.errors.map(err => err.message).join(', '))
    }

    const moduleItems = result.legacyNode?.moduleItems || []

    return {
      moduleItems: transformItems(moduleItems, moduleId),
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    showFlashError(I18n.t('Failed to load module items: %{error}', {error: errorMessage}))
    throw error
  }
}

export function useModuleItems(moduleId: string, enabled: boolean = false) {
  return useQuery<ModuleItemsResponse, Error>({
    queryKey: ['moduleItems', moduleId],
    queryFn: getModuleItems,
    enabled,
    // Don't refetch on window focus or reconnect if not enabled
    refetchOnWindowFocus: enabled,
    refetchOnReconnect: enabled,
    // Stale time of 5 minutes
    staleTime: 5 * 60 * 1000,
    meta: {
      broadcast: true, // Enable broadcasting for module items
    },
  })
}

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

import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/query/graphql'
import {ModuleItemsResponse, ModuleItemsGraphQLResult, ModuleItem} from '../../utils/types'
import {useQuery} from '@tanstack/react-query'

export const MODULE_ITEMS_STUDENT_QUERY = gql`
  query GetModuleItemsStudentQuery($moduleId: ID!) {
    legacyNode(_id: $moduleId, type: Module) {
      ... on Module {
        moduleItems {
          _id
          id
          url
          indent
          position
          content {
            ... on Assignment {
              _id
              id
              title
              type: __typename
              pointsPossible
              isNewQuiz
              published
              submissionsConnection(filter: {includeUnsubmitted: true}) {
                nodes {
                  _id
                  cachedDueDate
                  missing
                }
              }
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
            }
            ... on Page {
              _id
              id
              title
              published
              type: __typename
            }
            ... on Quiz {
              _id
              id
              title
              type: __typename
              pointsPossible
              published
            }
            ... on ExternalUrl {
              title
              type: __typename
              url
              published
              newTab
            }
            ... on ModuleExternalTool {
              title
              type: __typename
              url
              published
            }
            ... on SubHeader {
              title
              published
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
  }))
}

async function getModuleItemsStudent({queryKey}: {queryKey: any}): Promise<ModuleItemsResponse> {
  const [_key, moduleId] = queryKey

  const result = await executeQuery<ModuleItemsGraphQLResult>(MODULE_ITEMS_STUDENT_QUERY, {
    moduleId,
  })

  if (result.errors) {
    throw new Error(result.errors.map(err => err.message).join(', '))
  }

  const moduleItems = result.legacyNode?.moduleItems || []

  return {
    moduleItems: transformItems(moduleItems, moduleId),
  }
}

export function useModuleItemsStudent(moduleId: string, enabled: boolean = false) {
  return useQuery<ModuleItemsResponse, Error>({
    queryKey: ['moduleItemsStudent', moduleId],
    queryFn: getModuleItemsStudent,
    enabled,
    refetchOnWindowFocus: enabled,
    refetchOnReconnect: enabled,
  })
}

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
import {gql} from 'graphql-tag'
import {executeQuery} from '@canvas/graphql'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

// Define the types of content that can be added to a module
export type ModuleItemContentType =
  | 'assignment'
  | 'quiz'
  | 'file'
  | 'page'
  | 'discussion'
  | 'context_module_sub_header'
  | 'external_url'
  | 'external_tool'

// Base interface for all content items
export interface ContentItem {
  id: string
  name: string
}

// Common response structure for all queries
export interface ContentItemsResponse {
  items: ContentItem[]
  pageInfo?: {
    hasNextPage: boolean
    endCursor: string | null
  }
}

// Define GraphQL response interface
export interface GraphQLResponse {
  course?: {
    assignmentsConnection?: {
      nodes: Array<{
        _id: string
        name: string
        pointsPossible: number
        dueAt: string
        published: boolean
      }>
      pageInfo: {
        hasNextPage: boolean
        endCursor: string | null
      }
    }
    quizzesConnection?: {
      nodes: Array<{
        _id: string
        title: string
        pointsPossible: number
        published: boolean
      }>
      pageInfo: {
        hasNextPage: boolean
        endCursor: string | null
      }
    }
    pagesConnection?: {
      nodes: Array<{
        _id: string
        title: string
        order: number
      }>
      pageInfo: {
        hasNextPage: boolean
        endCursor: string | null
      }
    }
    discussionsConnection?: {
      nodes: Array<{
        _id: string
        title: string
        published: boolean
      }>
      pageInfo: {
        hasNextPage: boolean
        endCursor: string | null
      }
    }
    externalToolsConnection?: {
      nodes: Array<{
        _id: string
        id: string
        name: string
        url: string
      }>
      pageInfo: {
        hasNextPage: boolean
        endCursor: string | null
      }
    }
    filesConnection?: {
      nodes: Array<{
        _id: string
        id: string
        displayName: string
        contentType: string
        size: number
        published: boolean
      }>
      pageInfo: {
        hasNextPage: boolean
        endCursor: string | null
      }
    }
  }
  errors?: Array<{
    message: string
    locations?: Array<{
      line: number
      column: number
    }>
    path?: Array<string | number>
    extensions?: Record<string, any>
  }>
}

// Assignment query
const ASSIGNMENTS_QUERY = gql`
  query GetAssignmentsQuery($courseId: ID!, $searchTerm: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        assignmentsConnection(first: 100, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            name
            pointsPossible
            dueAt
            published
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

// Quiz query
const QUIZZES_QUERY = gql`
  query GetQuizzesQuery($courseId: ID!, $searchTerm: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        quizzesConnection(first: 100, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            title
            pointsPossible
            published
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

// Files query
const FILES_QUERY = gql`
  query GetFilesQuery($courseId: ID!, $searchTerm: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        filesConnection(first: 100, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            displayName
            contentType
            size
            published
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

// Pages query
const PAGES_QUERY = gql`
  query GetPagesQuery($courseId: ID!, $searchTerm: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        pagesConnection(first: 100, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            title
            published
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

// Discussions query
const DISCUSSIONS_QUERY = gql`
  query GetDiscussionsQuery($courseId: ID!, $searchTerm: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        discussionsConnection(first: 100, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            title
            published
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

// External tools query
const EXTERNAL_TOOLS_QUERY = gql`
  query GetExternalToolsQuery($courseId: ID!) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        externalToolsConnection(first: 100) {
          nodes {
            _id
            name
            url
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

// Function to get the appropriate query based on content type
function getQueryForContentType(contentType: ModuleItemContentType) {
  switch (contentType) {
    case 'assignment':
      return ASSIGNMENTS_QUERY
    case 'quiz':
      return QUIZZES_QUERY
    case 'file':
      return FILES_QUERY
    case 'page':
      return PAGES_QUERY
    case 'discussion':
      return DISCUSSIONS_QUERY
    case 'external_tool':
      return EXTERNAL_TOOLS_QUERY
    default:
      return null
  }
}

// Function to transform the query result into a standardized format
function transformQueryResult(
  contentType: ModuleItemContentType,
  result: GraphQLResponse,
): ContentItemsResponse {
  if (!result || result.errors) {
    return {items: []}
  }

  const course = result.course

  switch (contentType) {
    case 'assignment':
      return {
        items:
          course?.assignmentsConnection?.nodes?.map((node: any) => ({
            id: node._id,
            name: node.name,
            pointsPossible: node.pointsPossible,
            dueAt: node.dueAt,
            published: node.published,
          })) || [],
        pageInfo: course?.assignmentsConnection?.pageInfo,
      }
    case 'quiz':
      return {
        items:
          course?.quizzesConnection?.nodes?.map((node: any) => ({
            id: node._id,
            name: node.title,
            pointsPossible: node.pointsPossible,
            published: node.published,
          })) || [],
        pageInfo: course?.quizzesConnection?.pageInfo,
      }
    case 'file':
      return {
        items:
          course?.filesConnection?.nodes?.map((node: any) => ({
            id: node._id,
            name: node.displayName,
            contentType: node.contentType,
            size: node.size,
            published: node.published,
          })) || [],
        pageInfo: course?.filesConnection?.pageInfo,
      }
    case 'page':
      return {
        items:
          course?.pagesConnection?.nodes?.map((node: any) => ({
            id: node._id,
            name: node.title,
            published: node.published,
          })) || [],
        pageInfo: course?.pagesConnection?.pageInfo,
      }
    case 'discussion':
      return {
        items:
          course?.discussionsConnection?.nodes?.map((node: any) => ({
            id: node._id,
            name: node.title,
            published: node.published,
          })) || [],
        pageInfo: course?.discussionsConnection?.pageInfo,
      }
    case 'external_tool':
      return {
        items:
          course?.externalToolsConnection?.nodes?.map((node: any) => ({
            id: node._id,
            name: node.name,
            url: node.url,
          })) || [],
        pageInfo: course?.externalToolsConnection?.pageInfo,
      }
    case 'context_module_sub_header':
      // Text headers don't need to fetch data
      return {items: []}
    case 'external_url':
      // External URLs don't need to fetch data
      return {items: []}
    default:
      return {items: []}
  }
}

// Main function to fetch content items based on type
export async function getModuleItemContent({
  queryKey,
}: {
  queryKey: [string, ModuleItemContentType, string, string?]
}): Promise<ContentItemsResponse> {
  const [, contentType, courseId, searchTerm] = queryKey

  // Special cases that don't require API calls
  if (contentType === 'context_module_sub_header' || contentType === 'external_url') {
    return {items: []}
  }

  const query = getQueryForContentType(contentType)
  if (!query) {
    return {items: []}
  }

  try {
    const result = await executeQuery<GraphQLResponse>(query, {
      courseId,
      searchTerm: searchTerm || '',
    })

    if (result.errors) {
      throw new Error(result.errors.map(err => err.message).join(', '))
    }

    return transformQueryResult(contentType, result)
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    showFlashError(
      I18n.t('Failed to load %{contentType}: %{error}', {
        contentType: contentType,
        error: errorMessage,
      }),
    )
    throw error
  }
}

export function useModuleItemContent(
  contentType: ModuleItemContentType,
  courseId: string,
  searchTerm?: string,
  enabled: boolean = true,
) {
  return useQuery({
    queryKey: ['moduleItemContent', contentType, courseId, searchTerm],
    queryFn: getModuleItemContent,
    enabled:
      enabled && contentType !== 'context_module_sub_header' && contentType !== 'external_url',
    staleTime: 10 * 60 * 1000, // 10 minutes
  })
}

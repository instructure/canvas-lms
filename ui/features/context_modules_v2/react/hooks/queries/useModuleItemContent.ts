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

import {useInfiniteQuery} from '@tanstack/react-query'
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

export type placementContent = {
  title: string
  url: string
}

// Base interface for all content items
export interface ContentItem {
  id: string
  name: string
  // Applies to external tools and external URLs
  url?: string
  // Applies for external tools and module external tools.
  domain?: string
  description?: string
  placements?: Record<string, placementContent>
  // Applies for quizzes
  quizType?: 'quiz' | 'assignment'
  // Applies to assignments (for grouping)
  groupId?: string
  groupName?: string
}

// Common response structure for all queries
export interface ContentItemsResponse {
  items: ContentItem[]
  pageInfo?: {
    hasNextPage: boolean
    hasPreviousPage: boolean
    endCursor: string | null
    startCursor: string | null
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
        submissionTypes?: string[]
        dueAt: string
        published: boolean
        assignmentGroup?: {
          _id: string
          name: string
        }
      }>
      pageInfo: {
        hasNextPage: boolean
        hasPreviousPage: boolean
        endCursor: string | null
        startCursor: string | null
      }
    }
    quizzesConnection?: {
      nodes: Array<{
        _id: string
        title: string
        pointsPossible: number
        published: boolean
        type: 'assignment' | 'quiz'
      }>
      pageInfo: {
        hasNextPage: boolean
        hasPreviousPage: boolean
        endCursor: string | null
        startCursor: string | null
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
        hasPreviousPage: boolean
        endCursor: string | null
        startCursor: string | null
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
        hasPreviousPage: boolean
        endCursor: string | null
        startCursor: string | null
      }
    }
    externalToolsConnection?: {
      nodes: Array<{
        _id: string
        id: string
        name: string
        url: string
        placements: Record<string, any>
      }>
      pageInfo: {
        hasNextPage: boolean
        hasPreviousPage: boolean
        endCursor: string | null
        startCursor: string | null
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
        folder?: {
          _id: string
          name: string
          fullName: string
        }
      }>
      pageInfo: {
        hasNextPage: boolean
        hasPreviousPage: boolean
        endCursor: string | null
        startCursor: string | null
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
  query GetAssignmentsQuery($courseId: ID!, $searchTerm: String, $after: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        assignmentsConnection(first: 25, after: $after, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            name
            pointsPossible
            submissionTypes
            dueAt
            published
            assignmentGroup {
              _id
              name
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            endCursor
            startCursor
          }
        }
      }
    }
  }
`

// Quiz query
const QUIZZES_QUERY = gql`
  query GetQuizzesQuery($courseId: ID!, $searchTerm: String, $after: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        quizzesConnection(first: 25, after: $after, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            title
            pointsPossible
            published
            quizType
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            endCursor
            startCursor
          }
        }
      }
    }
  }
`

// Files query
const FILES_QUERY = gql`
  query GetFilesQuery($courseId: ID!, $searchTerm: String, $after: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        filesConnection(first: 25, after: $after, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            displayName
            contentType
            size
            published
            folder {
              _id
              name
              fullName
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            endCursor
            startCursor
          }
        }
      }
    }
  }
`

// Pages query
const PAGES_QUERY = gql`
  query GetPagesQuery($courseId: ID!, $searchTerm: String, $after: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        pagesConnection(first: 25, after: $after, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            title
            published
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            endCursor
            startCursor
          }
        }
      }
    }
  }
`

// Discussions query
const DISCUSSIONS_QUERY = gql`
  query GetDiscussionsQuery($courseId: ID!, $searchTerm: String, $after: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        discussionsConnection(first: 25, after: $after, filter: {searchTerm: $searchTerm}) {
          nodes {
            _id
            id
            title
            published
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            endCursor
            startCursor
          }
        }
      }
    }
  }
`

// External tools query
const EXTERNAL_TOOLS_QUERY = gql`
  query GetExternalToolsQuery($courseId: ID!, $after: String) {
    course: legacyNode(_id: $courseId, type: Course) {
      ... on Course {
        externalToolsConnection(first: 25, after: $after) {
          nodes {
            _id
            name
            description
            domain
            url
            placements {
              courseAssignmentsMenu {
                title
                url
              }
              moduleIndexMenuModal {
                title
                url
              }
              assignmentSelection {
                title
                url
              }
              linkSelection {
                title
                url
              }
              moduleMenuModal {
                title
                url
              }
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            endCursor
            startCursor
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

const hasQuizSubmissionType = (submissionTypes: unknown): boolean =>
  Array.isArray(submissionTypes) &&
  submissionTypes.some(
    (t: unknown) =>
      typeof t === 'string' &&
      (t.toLowerCase().includes('quiz') || t.toLowerCase() === 'external_tool'),
  )

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
            isQuiz: hasQuizSubmissionType(node?.submissionTypes),
            dueAt: node.dueAt,
            published: node.published,
            groupId: node.assignmentGroup?._id,
            groupName: node.assignmentGroup?.name,
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
            quizType: node.quizType,
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
            groupId: node.folder?._id,
            groupName: node.folder?.fullName || node.folder?.name,
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
            description: node.description,
            domain: node.domain,
            url: node.url,
            placements: node.placements,
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
export async function getModuleItemContent(context: any): Promise<ContentItemsResponse> {
  const {queryKey, pageParam} = context
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
      after: pageParam || null,
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
  return useInfiniteQuery({
    queryKey: ['moduleItemContent', contentType, courseId, searchTerm],
    queryFn: getModuleItemContent,
    enabled:
      enabled && contentType !== 'context_module_sub_header' && contentType !== 'external_url',
    staleTime: 10 * 60 * 1000,
    initialPageParam: undefined,
    getNextPageParam: lastPage => {
      if (lastPage.pageInfo?.hasNextPage && lastPage.pageInfo?.endCursor) {
        return lastPage.pageInfo.endCursor
      }
      return undefined
    },
  })
}

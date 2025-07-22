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

import {IssuesTableColumns} from '../constants'
import {AccessibilityData, ContentItem, ContentItemType} from '../types'

// COMMON API UTILS

const snakeToCamel = function (str: string): string {
  return str.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase())
}

export const convertKeysToCamelCase = function (input: any): object | boolean {
  if (Array.isArray(input)) {
    return input.map(convertKeysToCamelCase)
  } else if (input !== null && typeof input === 'object') {
    return Object.fromEntries(
      Object.entries(input).map(([key, value]) => [
        snakeToCamel(key),
        convertKeysToCamelCase(value),
      ]),
    )
  }
  return input !== null && input !== undefined ? input : {}
}

/*
 * FOR UPGRADED API
 * From this point, this file holds utility functions to process the raw response data
 * of the upgraded API implementation for the Accessibility Checker.
 */

//

/*
 * FOR INITIAL API
 * From this point, this file holds utility functions to process the raw response data
 * of the initial API implementation for the Accessibility Checker.
 *
 * These functions will be deprecated once the upgraded API is fully adopted.
 */

export const calculateTotalIssuesCount = (data?: AccessibilityData | null): number => {
  let total = 0
  ;['pages', 'assignments', 'attachments'].forEach(key => {
    const items = data?.[key as keyof AccessibilityData]
    if (items) {
      Object.values(items).forEach(item => {
        if (item.count) {
          total += item.count
        }
      })
    }
  })

  return total
}

/**
 * This method flattens the accessibility data structure from the current API
 * response data into a simple array of ContentItem objects.
 */
export const processAccessibilityData = (accessibilityIssues?: AccessibilityData | null) => {
  const flatData: ContentItem[] = []

  const processContentItems = (
    items: Record<string, ContentItem> | undefined,
    type: ContentItemType,
    defaultTitle: string,
  ) => {
    if (!items) return

    Object.entries(items).forEach(([id, itemData]) => {
      if (itemData) {
        flatData.push({
          id: Number(id),
          type,
          title: itemData?.title || defaultTitle,
          published: itemData?.published || false,
          updatedAt: itemData?.updatedAt || '',
          count: itemData?.count || 0,
          url: itemData?.url,
          editUrl: itemData?.editUrl,
        })
      }
    })
  }

  processContentItems(accessibilityIssues?.pages, ContentItemType.WikiPage, 'Untitled Page')

  processContentItems(
    accessibilityIssues?.assignments,
    ContentItemType.Assignment,
    'Untitled Assignment',
  )

  processContentItems(
    accessibilityIssues?.attachments,
    ContentItemType.Attachment,
    'Untitled Attachment',
  )

  return flatData
}

const sortAscending = (aValue: any, bValue: any): number => {
  if (aValue < bValue) return -1
  if (aValue > bValue) return 1
  return 0
}

const sortDescending = (aValue: any, bValue: any): number => {
  if (aValue < bValue) return 1
  if (aValue > bValue) return -1
  return 0
}

/**
 * TODO Remove, once the API is upgraded to support sorting.
 */
export const getSortingFunction = (sortId: string, sortDirection: 'ascending' | 'descending') => {
  const sortFn = sortDirection === 'ascending' ? sortAscending : sortDescending

  if (sortId === IssuesTableColumns.ResourceName) {
    return (a: ContentItem, b: ContentItem) => {
      return sortFn(a.title, b.title)
    }
  }
  if (sortId === IssuesTableColumns.Issues) {
    return (a: ContentItem, b: ContentItem) => {
      return sortFn(a.count, b.count)
    }
  }
  if (sortId === IssuesTableColumns.ResourceType) {
    return (a: ContentItem, b: ContentItem) => {
      return sortFn(a.type, b.type)
    }
  }
  if (sortId === IssuesTableColumns.State) {
    return (a: ContentItem, b: ContentItem) => {
      // Published items first by default
      return sortFn(a.published ? 0 : 1, b.published ? 0 : 1)
    }
  }
  if (sortId === IssuesTableColumns.LastEdited) {
    return (a: ContentItem, b: ContentItem) => {
      return sortFn(a.updatedAt, b.updatedAt)
    }
  }
}

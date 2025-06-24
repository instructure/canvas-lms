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

import {AccessibilityData, ContentItem, ContentItemType} from './types'

/**
 * This method should be deprecated, once the API will be upgraded
 * to support pagination.
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
 * - Should be deprecated, once the API will be upgraded to support pagination.
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

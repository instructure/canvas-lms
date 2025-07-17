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
import {
  AccessibilityData,
  AccessibilityResourceScan,
  ContentItem,
  ContentItemType,
  FilterDateKeys,
  Filters,
  ParsedFilters,
  Severity,
} from '../types'

// COMMON API UTILS

const snakeToCamel = function (str: string): string {
  return str.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase())
}

export const convertKeysToCamelCase = function (input: any): object | boolean | string {
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
  return input !== null && input !== undefined ? input : ''
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

export const getParsedFilters = (filters: Filters | null): ParsedFilters => {
  const parsed = {} as ParsedFilters
  if (filters) {
    ;(Object.keys(filters) as Array<keyof Filters>).forEach((key: keyof Filters) => {
      const typedKey = key as keyof Filters
      const value = filters[typedKey]
      if (Array.isArray(value)) {
        ;(parsed[typedKey] as any) = value.includes('all') ? undefined : value
      } else if (value instanceof Date) {
        parsed[typedKey as FilterDateKeys] = value.toISOString() as string
      } else {
        parsed[typedKey] = value ?? undefined
      }
    })
  }

  return parsed || {}
}

export function issueSeverity(count: number): Severity {
  if (count > 30) return 'High'
  if (count > 2) return 'Medium'
  return 'Low'
}

export function parseAccessibilityScans(scans: any[]): AccessibilityData {
  const pages: Record<string, ContentItem> = {}
  const assignments: Record<string, ContentItem> = {}
  const attachments: Record<string, ContentItem> = {}

  for (const scan of scans) {
    const resourceId = String(scan.resourceId)
    const resourceType = scan.resourceType as ContentItemType

    const contentItem: ContentItem = {
      id: Number(resourceId),
      type: resourceType,
      title: scan.resourceName ?? '',
      published: scan.resourceWorkflowState === 'published',
      updatedAt: scan.resourceUpdatedAt || new Date().toISOString(),
      count: scan.issueCount,
      url: scan.resourceUrl,
      editUrl: `${scan.resourceUrl}/edit`,
      issues: scan.issues ?? [],
      severity: issueSeverity(scan.issueCount),
    }

    if (resourceType === ('WikiPage' as ContentItemType)) {
      pages[resourceId] = contentItem
    } else if (resourceType === ('Assignment' as ContentItemType)) {
      assignments[resourceId] = contentItem
    } else if (resourceType === ('Attachment' as ContentItemType)) {
      attachments[resourceId] = contentItem
    }
  }

  return {
    pages,
    assignments,
    attachments,
    lastChecked: new Date().toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    }),
    accessibilityScanDisabled: false,
  }
}

export function parseScansToContentItems(scans: AccessibilityResourceScan[]): ContentItem[] {
  return scans.map(
    (scan): ContentItem => ({
      id: scan.resourceId,
      type: (scan.resourceType === 'WikiPage' ? 'Page' : scan.resourceType) as ContentItemType,
      title: scan.resourceName ?? '',
      published: scan.resourceWorkflowState === 'published',
      updatedAt: scan.resourceUpdatedAt,
      count: scan.issueCount,
      url: scan.resourceUrl,
      editUrl: `${scan.resourceUrl}/edit`,
      issues: scan.issues,
      severity: issueSeverity(scan.issueCount), // you can compute severity from issues if needed
    }),
  )
}

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

import {
  AccessibilityResourceScan,
  ContentItem,
  ContentItemType,
  FilterOption,
  Filters,
  HasId,
  ParsedFilters,
  ResourceType,
  ResourceWorkflowState,
  ScanWorkflowState,
  Severity,
} from '../types'
import {FILTER_GROUP_MAPPING} from '../../../accessibility_checker/react/constants'

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

export const getAsContentItem = (scan: AccessibilityResourceScan): ContentItem => {
  return {
    id: scan.resourceId,
    type: scan.resourceType,
    title: scan.resourceName ?? '',
    published: scan.resourceWorkflowState === 'published',
    updatedAt: scan.resourceUpdatedAt,
    count: scan.issueCount,
    url: scan.resourceUrl,
    editUrl: `${scan.resourceUrl}/edit`,
    issues: scan.issues,
    severity: getIssueSeverity(scan.issueCount),
  }
}

export const getAsAccessibilityResourceScan = (item: ContentItem): AccessibilityResourceScan => {
  return {
    id: item.id,
    resourceId: item.id,
    resourceType: item.type as ResourceType,
    resourceName: item.title,
    resourceWorkflowState: item.published
      ? ResourceWorkflowState.Published
      : ResourceWorkflowState.Unpublished,
    resourceUpdatedAt: item.updatedAt,
    resourceUrl: item.url,
    workflowState: ScanWorkflowState.Completed,
    issueCount: item.count,
    issues: item.issues || [],
  }
}

// Backwards compatibility for remediation APIs
export const getAsContentItemType = (type?: ResourceType): ContentItemType | undefined => {
  if (!type) return undefined

  switch (type) {
    case ResourceType.WikiPage:
      return ContentItemType.WikiPage
    case ResourceType.Assignment:
      return ContentItemType.Assignment
    case ResourceType.Attachment:
      return ContentItemType.Attachment
  }
}

export const findById = <T extends HasId>(data: T[] | null, id: string | number): T | undefined => {
  const stringId = String(id)
  return data?.find(item => {
    return item.id === stringId
  })
}

export const replaceById = <T extends HasId>(data: T[] | null, item: T): T[] => {
  if (!data) return []
  return data.map(existingItem => (existingItem.id === item.id ? item : existingItem))
}

export const calculateTotalIssuesCount = (data?: AccessibilityResourceScan[] | null): number => {
  if (!data) return 0

  return data.reduce((total, scan) => {
    return total + (scan.issueCount || 0)
  }, 0)
}

const formatDateFilter = (date?: string) => {
  if (date) {
    const dateFormatter = new Intl.DateTimeFormat('en-US', {
      weekday: 'short',
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    }).format

    return {
      label: dateFormatter(new Date(date)),
      value: new Date(date).toISOString(),
    }
  }
  return undefined
}

export const getUnparsedFilters = (parsedFilters: ParsedFilters): Filters => {
  const toFilterOptionArray = (values?: string[]): FilterOption[] | undefined => {
    if (!values) return undefined
    return values.map(value => ({value, label: value}))
  }

  return {
    ruleTypes: toFilterOptionArray(parsedFilters.ruleTypes),
    artifactTypes: toFilterOptionArray(parsedFilters.artifactTypes),
    workflowStates: toFilterOptionArray(parsedFilters.workflowStates),
    fromDate: formatDateFilter(parsedFilters.fromDate),
    toDate: formatDateFilter(parsedFilters.toDate),
  }
}

export const getParsedFilters = (filters: Filters | null): ParsedFilters => {
  if (!filters) return {}

  const hasAll = (opts?: FilterOption[]) => !!opts?.some(o => o?.value?.toLowerCase?.() === 'all')

  const toValueArray = (opts?: FilterOption[]): string[] | undefined => {
    if (!opts || opts.length === 0) return undefined
    return hasAll(opts) ? undefined : opts.map(o => o.value)
  }

  const expandRuleTypes = (ruleTypes?: string[]): string[] | undefined => {
    if (!ruleTypes) return undefined

    const expanded: string[] = []
    for (const ruleType of ruleTypes) {
      if (ruleType in FILTER_GROUP_MAPPING) {
        expanded.push(...FILTER_GROUP_MAPPING[ruleType as keyof typeof FILTER_GROUP_MAPPING])
      } else {
        expanded.push(ruleType)
      }
    }
    return expanded
  }

  const parsed: ParsedFilters = {}
  const ruleTypes = toValueArray(filters.ruleTypes)
  const expandedRuleTypes = expandRuleTypes(ruleTypes)
  if (expandedRuleTypes) parsed.ruleTypes = expandedRuleTypes

  const artifactTypes = toValueArray(filters.artifactTypes)
  if (artifactTypes) parsed.artifactTypes = artifactTypes

  const workflowStates = toValueArray(filters.workflowStates)
  if (workflowStates) parsed.workflowStates = workflowStates

  if (filters.fromDate?.value) parsed.fromDate = filters.fromDate?.value

  if (filters.toDate?.value) parsed.toDate = filters.toDate?.value

  return parsed
}

export const getIssueSeverity = (count: number): Severity => {
  if (count > 30) return 'High'
  if (count > 2) return 'Medium'
  return 'Low'
}

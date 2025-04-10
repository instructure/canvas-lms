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

// Shared types for the accessibility checker

// Define types for accessibility issues and correction forms data structure
export interface FormField {
  label: string
  data_key: string
  checkbox?: boolean
  options?: Array<[string, string]>
  placeholder?: string
  disabled?: boolean
}

export interface FormDefinition {
  rule_id: string
  resource_type: string
  resource_id: string
  prefix: string
  fields: FormField[]
}

export enum IssueSeverity {
  High = 'high',
  Medium = 'medium',
  Low = 'low',
  None = 'none',
}

export enum ContentItemType {
  Page = 'page',
  Assignment = 'assignment',
}

export interface AccessibilityIssue {
  id: string
  rule_id?: string
  message: string
  why: string
  element: string
  path: string
  severity: IssueSeverity
  data?: Record<string, any>
  form?: FormField[]
}

export interface ContentItemIssues {
  edit_url: string
  url: string
  count: number
  severity: IssueSeverity
  issues: AccessibilityIssue[]
  title?: string
  display_name?: string
  published?: boolean
  locked?: boolean
  updated_at?: string
}

export interface AccessibilityData {
  pages?: Record<string, ContentItemIssues>
  assignments?: Record<string, ContentItemIssues>
  files?: Record<string, ContentItemIssues>
  last_checked?: string
}

// Used across components - ensures consistent typing between components
export interface ContentItem {
  id: string
  type: ContentItemType
  name: string
  contentType: string
  published: boolean
  updatedAt: string
  count: number
  severity: IssueSeverity
  url: string
  editUrl: string
  issues?: AccessibilityIssue[]
}

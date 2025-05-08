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
  issueUrl?: string
}

export interface AccessibilityData {
  pages?: Record<string, ContentItem>
  assignments?: Record<string, ContentItem>
  lastChecked?: string
}

export interface ContentItem {
  id: string
  type: ContentItemType
  title: string
  contentType: string
  published: boolean
  updatedAt: string
  count: number
  url: string
  editUrl: string
  issues?: AccessibilityIssue[]
}

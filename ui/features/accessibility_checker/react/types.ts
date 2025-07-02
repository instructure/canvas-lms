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
  WikiPage = 'Page',
  Assignment = 'Assignment',
  Attachment = 'attachment',
}

export enum FormType {
  TextInput = 'textinput',
  DropDown = 'dropdown',
  Checkbox = 'checkbox',
  ColorPicker = 'colorpicker',
}

export interface IssueForm {
  type: FormType
  label?: string
  value?: string
  options?: string[]
}

export interface AccessibilityIssue {
  id: string
  ruleId?: RuleId
  message: string
  why: string
  element: string
  path: string
  issueUrl?: string
  form: IssueForm
}

export interface AccessibilityData {
  pages?: Record<string, ContentItem>
  assignments?: Record<string, ContentItem>
  attachments?: Record<string, ContentItem>
  lastChecked?: string
}

export interface ContentItem {
  id: number
  type: ContentItemType
  title: string
  published: boolean
  updatedAt: string
  count: number
  url: string
  editUrl?: string
  issues?: AccessibilityIssue[]
  severity?: Severity
}

export interface PreviewResponse {
  content: string
  path?: string
}

export type FormValue = any

export type Severity = 'High' | 'Medium' | 'Low'

export type IssueDataPoint = {
  id: string
  issue: string
  count: number
  severity: Severity
}

export type RawData = Record<string, any>

export type RuleId =
  | 'adjacent-links'
  | 'headings-sequence'
  | 'has-lang-entry'
  | 'headings-start-at-h2'
  | 'img-alt'
  | 'img-alt-filename'
  | 'img-alt-length'
  | 'large-text-contrast'
  | 'small-text-contrast'
  | 'list-structure'
  | 'paragraphs-for-headings'
  | 'table-caption'
  | 'table-header'
  | 'table-header-scope'

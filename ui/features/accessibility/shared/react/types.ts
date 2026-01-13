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

export interface HasId {
  id: number | string
}

export enum ContentItemType {
  WikiPage = 'Page',
  Assignment = 'Assignment',
  Attachment = 'attachment',
  DiscussionTopic = 'DiscussionTopic',
}

/* export const ContentTypeToKey = {
  [ContentItemType.WikiPage]: 'pages',
  [ContentItemType.Assignment]: 'assignments',
  [ContentItemType.Attachment]: 'attachments',
} as const */

export enum FormType {
  TextInput = 'textinput',
  RadioInputGroup = 'radio_input_group',
  Button = 'button',
  ColorPicker = 'colorpicker',
  CheckboxTextInput = 'checkbox_text_input',
}

export interface IssueForm {
  type: FormType
  label?: string
  undoText?: string
  canGenerateFix?: boolean
  isCanvasImage?: boolean
  generateButtonLabel?: string
  value?: string
  options?: string[]
  action?: string
  inputLabel?: string
  titleLabel?: string
  backgroundColor?: string
  contrastRatio?: number
  checkboxLabel?: string
  checkboxSubtext?: string
  inputDescription?: string
  inputMaxLength?: number
}

export enum IssueWorkflowState {
  Active = 'active',
  Dismissed = 'dismissed',
  Resolved = 'resolved',
}

export enum ScanWorkflowState {
  Queued = 'queued',
  InProgress = 'in_progress',
  Completed = 'completed',
  Failed = 'failed',
}

export enum ResourceWorkflowState {
  Unpublished = 'unpublished',
  Published = 'published',
}

export enum ResourceType {
  WikiPage = 'WikiPage',
  Assignment = 'Assignment',
  Attachment = 'Attachment',
  DiscussionTopic = 'DiscussionTopic',
}

export interface AccessibilityResourceScan extends HasId {
  id: number
  courseId: number
  resourceId: number
  resourceType: ResourceType
  resourceName: string
  resourceWorkflowState: ResourceWorkflowState
  resourceUpdatedAt: string
  resourceUrl: string
  workflowState: ScanWorkflowState
  errorMessage?: string
  issueCount: number
  issues?: AccessibilityIssue[]
  closedAt?: string | null
  closedIssueCount?: number
}

export interface AccessibilityIssue {
  id: string
  ruleId: string
  displayName: string
  message: string
  why: string | string[]
  element: string
  path: string
  issueUrl?: string
  form: IssueForm
  workflowState: IssueWorkflowState
}

export interface AccessibilityIssuesSummaryData {
  total: number
  byRuleType: Record<string, number>
}

export interface ContentItem extends HasId {
  id: number
  type: ResourceType // Was ContentItemType
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

export interface ColorContrastPreviewResponse extends PreviewResponse {
  background: string
  foreground: string
}

export type FormValue = any

export type Severity = 'High' | 'Medium' | 'Low'

export type IssueDataPoint = {
  id?: string // not sure if we need this anymore
  issue: string
  count: number
  severity: Severity
}

export type ContrastData = {
  contrast: number
  isValidNormalText: boolean
  isValidLargeText: boolean
  isValidGraphicsText: boolean
  firstColor: string
  secondColor: string
}

export type GenerateResponse = {
  value?: string
}

export type FilterOption = {
  label: string
  value: string
}

export type Filters = {
  ruleTypes?: FilterOption[]
  artifactTypes?: FilterOption[]
  workflowStates?: FilterOption[]
  fromDate?: FilterOption | null
  toDate?: FilterOption | null
}

export type FilterDateKeys = 'fromDate' | 'toDate'

export type ParsedFilters = {
  ruleTypes?: string[]
  artifactTypes?: string[]
  workflowStates?: string[]
  fromDate?: string
  toDate?: string
}

export interface AppliedFilter {
  key: keyof Filters
  option: FilterOption
}

export type IssueRuleType =
  | 'small-text-contrast'
  | 'table-header-scope'
  | 'img-alt'
  | 'large-text-contrast'
  | 'list-structure'
  | 'headings-sequence'
  | 'img-alt-length'
  | 'table-header'
  | 'table-caption'
  | 'headings-start-at-h2'
  | 'link-text'
  | 'link-purpose'
  | 'adjacent-links'
  | 'has-lang-entry'
  | 'img-alt-filename'
  | 'paragraphs-for-headings'

export type FilterGroupMapping = {
  'alt-text': IssueRuleType[]
  'heading-order': IssueRuleType[]
  'text-contrast': IssueRuleType[]
}

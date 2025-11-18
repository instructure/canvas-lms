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

import {useScope as createI18nScope} from '@canvas/i18n'

import {IssueRuleType, Severity, FilterGroupMapping} from '../../shared/react/types'

const I18n = createI18nScope('accessibility_checker')

export const severityColors: Record<Severity, string> = {
  High: '#9B181C', // Red82
  Medium: '#E62429', // red45
  Low: '#F06E26', // orange30
}

export const LIMIT_EXCEEDED_MESSAGE = I18n.t(
  'The Course Accessibility Checker is not yet available for courses with more than 1,000 resources (pages and assignments combined).',
)

export const API_FETCH_ERROR_MESSAGE_PREFIX = I18n.t(
  'Error loading accessibility issues. Error is: ',
)

export const IssuesTableColumns = {
  ResourceName: 'resource-name-header',
  Issues: 'issues-header',
  ResourceType: 'resource-type-header',
  State: 'state-header',
  LastEdited: 'last-edited-header',
}

export const IssuesTableColumnHeaders = [
  {id: IssuesTableColumns.ResourceName, name: I18n.t('Resource Name')},
  {id: IssuesTableColumns.Issues, name: I18n.t('Issues')},
  {id: IssuesTableColumns.ResourceType, name: I18n.t('Resource Type')},
  {id: IssuesTableColumns.State, name: I18n.t('State')},
  {id: IssuesTableColumns.LastEdited, name: I18n.t('Last Edited')},
]

export const IssuesTableHeaderApiNames: Record<string, string> = {
  [IssuesTableColumns.ResourceName]: 'resource_name',
  [IssuesTableColumns.Issues]: 'issue_count',
  [IssuesTableColumns.ResourceType]: 'resource_type',
  [IssuesTableColumns.State]: 'resource_workflow_state',
  [IssuesTableColumns.LastEdited]: 'resource_updated_at',
}

export const FILTER_GROUP_MAPPING: FilterGroupMapping = {
  'alt-text': ['img-alt', 'img-alt-filename', 'img-alt-length'],
  'heading-order': ['headings-sequence', 'headings-start-at-h2'],
  'text-contrast': ['large-text-contrast', 'small-text-contrast'],
}

export const issueTypeOptions: {value: keyof FilterGroupMapping | IssueRuleType; label: string}[] =
  [
    {value: 'alt-text', label: I18n.t('Alt text')},
    {value: 'heading-order', label: I18n.t('Heading order')},
    {value: 'paragraphs-for-headings', label: I18n.t('Heading length')},
    {value: 'adjacent-links', label: I18n.t('Duplicate links')},
    {value: 'table-header', label: I18n.t('Missing table headers')},
    {value: 'table-header-scope', label: I18n.t('Table headers set up incorrectly')},
    {value: 'table-caption', label: I18n.t('Missing table caption')},
    {value: 'list-structure', label: I18n.t('List formatting')},
    {value: 'text-contrast', label: I18n.t('Text contrast')},
  ]

export const artifactTypeOptions = [
  {value: 'wiki_page', label: I18n.t('Pages')},
  {value: 'assignment', label: I18n.t('Assignments')},
]

export const stateOptions = [
  {value: 'published', label: I18n.t('Published')},
  {value: 'unpublished', label: I18n.t('Unpublished')},
  {value: 'archived', label: I18n.t('Archived')},
]

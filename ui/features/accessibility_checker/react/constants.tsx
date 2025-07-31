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

import {ContentItemType, Severity} from './types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

export const TypeToKeyMap: Record<ContentItemType, 'pages' | 'assignments' | 'attachments'> = {
  [ContentItemType.WikiPage]: 'pages',
  [ContentItemType.Assignment]: 'assignments',
  [ContentItemType.Attachment]: 'attachments',
}

export const severityColors: Record<Severity, string> = {
  High: '#9B181C', // Red82
  Medium: '#E62429', // red45
  Low: '#F06E26', // orange30
}

export const LIMIT_EXCEEDED_MESSAGE = I18n.t(
  'The Course Accessibility Checker is not yet available for courses with more than 1,000 resources (pages and assignments combined).',
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

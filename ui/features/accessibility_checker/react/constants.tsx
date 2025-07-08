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

export const ruleIdToLabelMap: Record<string, string> = {
  'adjacent-links': I18n.t('Adjacent links'),
  'headings-sequence': I18n.t('Skipped heading level'),
  'has-lang-entry': I18n.t('PDF language entry'),
  'headings-start-at-h2': I18n.t('Headings start at H2'),
  'img-alt': I18n.t('Image alt text missing'),
  'img-alt-filename': I18n.t('Image alt filename'),
  'img-alt-length': I18n.t('Image alt text length'),
  'large-text-contrast': I18n.t('Large text contrast'),
  'small-text-contrast': I18n.t('Small text contrast'),
  'list-structure': I18n.t('List structure'),
  'paragraphs-for-headings': I18n.t('Heading is too long'),
  'table-caption': I18n.t('Table caption'),
  'table-header': I18n.t('Table headers aren’t set up'),
  'table-header-scope': I18n.t('Table header scope'),
}

export const severityColors: Record<Severity, string> = {
  High: '#9B181C', // Red82
  Medium: '#E62429', // red45
  Low: '#F06E26', // orange30
}

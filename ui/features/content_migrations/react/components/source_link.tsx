/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {ContentMigrationItem} from './types'

const I18n = useI18nScope('content_migrations_redesign')

const obtainText = ({
  migration_type,
  attachment,
  settings,
  workflow_state,
}: ContentMigrationItem): string | null | undefined => {
  if (migration_type === 'course_copy_importer' && settings?.source_course_name) {
    return settings.source_course_name
  } else if (
    migration_type === 'canvas_cartridge_importer' &&
    workflow_state === 'completed' &&
    settings?.source_course_name
  ) {
    return settings.source_course_name
  }
  // For uncompleted canvas_cartridge_importer, zip_file_importer, common_cartridge_importer, moodle_converter & qti_converter
  return attachment ? attachment.display_name : I18n.t('File not available')
}

const obtainLink = ({
  migration_type,
  attachment,
  settings,
  workflow_state,
}: ContentMigrationItem): string | null | undefined => {
  if (migration_type === 'course_copy_importer' && settings?.source_course_html_url) {
    return settings.source_course_html_url
  } else if (
    migration_type === 'canvas_cartridge_importer' &&
    workflow_state === 'completed' &&
    settings?.source_course_html_url
  ) {
    return settings.source_course_html_url
  }
  // For uncompleted canvas_cartridge_importer, zip_file_importer, common_cartridge_importer, moodle_converter & qti_converter
  return attachment ? attachment.url : null
}

export const SourceLink = ({item}: {item: ContentMigrationItem}) => {
  const text = obtainText(item)
  const link = obtainLink(item)

  return link ? <Link href={link}>{text}</Link> : <Text>{text}</Text>
}

/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {type Folder, type File} from '../interfaces/File'
import {
  getIconByType,
  ICON_TITLES,
  DEFAULT_ICON_TITLE,
} from '@canvas/mime/react/mimeClassIconHelper'
import React from 'react'
import {IconFolderLockedSolid, IconFolderSolid} from '@instructure/ui-icons'
import {SVGIconProps} from '@instructure/ui-svg-images'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('files_v2')

export const isFile = (item: File | Folder): item is File => {
  return 'display_name' in item
}

// files and folders can share the same id,
// and UUIDs have been removed from the API
export const getUniqueId = (item: File | Folder) => {
  return isFile(item) ? `file-${item.id}` : `folder-${item.id}`
}

export const getIdFromUniqueId = (uniqueId: string) => {
  return uniqueId.split('-')[1]
}

export const pluralizeContextTypeString = (contextType: string) => `${contextType.toLowerCase()}s`

export const getIcon = (
  item: File | Folder,
  isFile: boolean,
  iconUrl?: string,
  iconProps?: SVGIconProps,
) => {
  if (isFile) {
    if (!iconUrl) {
      const IconComponent = getIconByType(item.mime_class)
      return React.cloneElement(IconComponent, {color: 'primary', ...iconProps})
    }
  } else {
    return item.for_submissions ? (
      <IconFolderLockedSolid
        title={I18n.t('Folder Locked')}
        data-testid="locked-folder-icon"
        color="primary"
        {...iconProps}
      />
    ) : (
      <IconFolderSolid
        title={I18n.t('Folder')}
        data-testid="folder-icon"
        color="primary"
        {...iconProps}
      />
    )
  }
}

export const getCheckboxLabel = (item: File | Folder): string => {
  let type
  if (isFile(item)) {
    type = ICON_TITLES[item.mime_class as keyof typeof ICON_TITLES] || DEFAULT_ICON_TITLE
  } else {
    type = item.for_submissions ? ICON_TITLES['folder-locked'] : ICON_TITLES['folder']
  }
  const name = getName(item)
  return I18n.t('%{type} %{name}', {type, name})
}

export const getName = (item: File | Folder) => {
  // files can have display_name or filename but prefer display_name
  // folders just have name
  return isFile(item) ? item.display_name || item.filename : item.name
}

export const isLockedBlueprintItem = (item: File | Folder) => {
  // only files can be locked, folders contain locked files
  if (!isFile(item)) return false
  return !!(
    item.folder_id &&
    item.restricted_by_master_course &&
    item.is_master_course_child_content
  )
}

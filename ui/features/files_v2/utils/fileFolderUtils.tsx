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
import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'
import React from 'react'
import {IconFolderLockedSolid, IconFolderSolid} from '@instructure/ui-icons'
import {SVGIconProps} from '@instructure/ui-svg-images'

export const isFile = (item: File | Folder): item is File => {
  return 'display_name' in item
}

export const getUniqueId = (item: File | Folder) => {
  return isFile(item) ? item.uuid : item.id
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
      <IconFolderLockedSolid data-testid="locked-folder-icon" color="primary" {...iconProps} />
    ) : (
      <IconFolderSolid data-testid="folder-icon" color="primary" {...iconProps} />
    )
  }
}

export const getName = (item: File | Folder) => {
  return isFile(item) ? item.display_name : item.name
}

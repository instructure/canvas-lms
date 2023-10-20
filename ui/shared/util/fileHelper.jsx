/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'

const I18n = useI18nScope('shared_components')

export const formatFileSize = (bytes, decimals = 2) => {
  if (bytes === 0) return '0 B'

  const k = 1024
  const dm = decimals < 0 ? 0 : decimals
  const sizes = ['B', 'KB', 'MB', 'GB']

  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / k ** i).toFixed(dm))} ${sizes[i]}`
}

/*
 * This is to account for files obtained through both graphql and
 * through the files API
 */
const standardizeToFilesAPI = file => {
  file.mime_class = file.mime_class || file.mimeClass
  file.display_name = file.display_name || file.displayName
  file.thumbnail_url = file.thumbnail_url || file.thumbnailUrl
  return file
}

export const getFileThumbnail = (file, iconSize = 'medium') => {
  const iconSizes = {
    'x-small': '1.125rem',
    small: '2rem',
    medium: '3rem',
    large: '5rem',
    'x-large': '10rem',
  }
  standardizeToFilesAPI(file)
  const size = iconSizes.hasOwnProperty(iconSize) ? iconSize : 'medium'
  if (file.mime_class === 'image' && file.thumbnail_url) {
    return (
      <img
        alt={I18n.t('%{filename} preview', {filename: file.display_name})}
        src={file.thumbnail_url}
        style={{
          height: iconSizes[size],
          width: iconSizes[size],
        }}
      />
    )
  }
  return React.cloneElement(getIconByType(file.mime_class), {size})
}

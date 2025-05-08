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
import {datetimeString} from '@canvas/datetime/date-functions'
import {type File, type Folder} from '../interfaces/File'
import {Tool} from '@canvas/files_v2/react/modules/filesEnvFactory.types'

const I18n = createI18nScope('files_v2')

export const isPublished = (item: File | Folder) => !item.locked
export const isRestricted = (item: File | Folder) => !!item.lock_at || !!item.unlock_at
export const isHidden = (item: File | Folder) => !!item.hidden

export const getRestrictedText = (item: File | Folder) => {
  if (item.unlock_at && item.lock_at) {
    return I18n.t('Available from %{from_date} until %{until_date}', {
      from_date: datetimeString(item.unlock_at),
      until_date: datetimeString(item.lock_at),
    })
  } else if (item.unlock_at) {
    return I18n.t('Available from %{from_date}', {
      from_date: datetimeString(item.unlock_at),
    })
  } else if (item.lock_at) {
    return I18n.t('Available until %{until_date}', {
      until_date: datetimeString(item.lock_at),
    })
  }
}

export const generatePreviewUrlPath = (item: File | Folder) => {
  if (!item.context_asset_string || !item.id) {
    throw new Error('File must have context_asset_string and id properties')
  }
  const [contextModel, contextId] = item.context_asset_string.split('_')
  if (!contextModel || !contextId) {
    throw new Error('Invalid context_asset_string format')
  }
  return `?preview=${item.id}`
}

export const externalToolEnabled = (file: File, tool: Tool) => {
  if (tool.accept_media_types && tool.accept_media_types.length > 0) {
    const content_type = file?.['content-type']
    return tool.accept_media_types.split(',').some(t => {
      const regex = new RegExp('^' + t.replace('*', '.*') + '$')
      return content_type?.match(regex)
    })
  } else {
    return true
  }
}

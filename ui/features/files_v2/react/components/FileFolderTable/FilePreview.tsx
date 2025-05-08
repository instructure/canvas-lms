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

import {Flex} from '@instructure/ui-flex'
import StudioMediaPlayer from '@canvas/canvas-studio-player'
import {type File} from '../../../interfaces/File'
import {isLockedBlueprintItem} from '../../../utils/fileFolderUtils'
import NoFilePreviewAvailable from './NoFilePreviewAvailable'
import FilePreviewIframe from './FilePreviewIframe'

const previewableTypes = ['image', 'pdf', 'html', 'doc', 'text']
const mediaTypes = ['video', 'audio']

export interface FilePreviewProps {
  item: File
}

export const FilePreview = ({item}: FilePreviewProps) => {
  const isFilePreview = !!(item.preview_url && previewableTypes.includes(item.mime_class))
  const isMediaPreview = !isFilePreview && mediaTypes.includes(item.mime_class)

  if (isFilePreview) {
    return <FilePreviewIframe item={item} />
  } else if (isMediaPreview) {
    return (
      <Flex as="div" alignItems="center" height="100%" justifyItems="center">
        <StudioMediaPlayer
          is_attachment={true}
          attachment_id={item.id.toString()}
          show_loader={true}
          isInverseVariant={true}
          hideUploadCaptions={isLockedBlueprintItem(item)}
          explicitSize={{
            width: '100%',
            height: '100%',
          }}
        />
      </Flex>
    )
  } else {
    return <NoFilePreviewAvailable item={item} />
  }
}

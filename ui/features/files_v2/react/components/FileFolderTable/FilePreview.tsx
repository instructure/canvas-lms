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

import {Suspense} from 'react'
import {Flex} from '@instructure/ui-flex'

import StudioMediaPlayer from '@canvas/canvas-studio-player'
import {MediaTrack} from '@canvas/canvas-studio-player/react/types'

import {type File} from '../../../interfaces/File'
import NoFilePreviewAvailable from './NoFilePreviewAvailable'
import FilePreviewIframe from './FilePreviewIframe'
import LoadingIndicator from '@canvas/loading-indicator/react'

export interface FilePreviewProps {
  item: File
  isFilePreview: boolean
  isMediaPreview: boolean
  mediaId: string
  mediaSources: any[]
  mediaTracks: MediaTrack[]
  isFetchingMedia: boolean
}

export const mediaTypes = ['video', 'audio']

export const FilePreview = ({
  item,
  isFilePreview,
  isMediaPreview,
  mediaId,
  mediaSources,
  mediaTracks,
  isFetchingMedia,
}: FilePreviewProps) => {
  if (isFilePreview) {
    return <FilePreviewIframe item={item} />
  } else if (isMediaPreview) {
    return (
      <Flex as="div" alignItems="center" height="100%" justifyItems="center">
        {isFetchingMedia ? (
          <Flex.Item>
            <LoadingIndicator />
          </Flex.Item>
        ) : (
          <Suspense>
            <StudioMediaPlayer
              media_id={mediaId}
              type={
                mediaTypes.includes(item.mime_class)
                  ? (item.mime_class as 'video' | 'audio')
                  : undefined
              }
              media_sources={mediaSources}
              media_tracks={mediaTracks}
              is_attachment={true}
              attachment_id={item.id}
              show_loader={!mediaSources?.length}
              hideUploadCaptions={true}
              explicitSize={{
                width: '100%',
                height: '100%',
              }}
            />
          </Suspense>
        )}
      </Flex>
    )
  } else {
    return <NoFilePreviewAvailable item={item} />
  }
}

// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import CanvasMediaPlayer from '@canvas/canvas-media-player'
import {RemovableItem} from '../RemovableItem/RemovableItem'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {colors} from '@instructure/canvas-theme'

const I18n = useI18nScope('conversations_2')

type MediaAttachmentProps = {
  onRemoveMediaComment?: () => void
  file: {
    mediaID: string
    mediaTracks?: {
      id: string
      src: string
      label: string
      type: string
      language: string
    }[]
    title: string
    src?: string
    mediaSources?: {
      type: string
      src: string
      height: string
      width: string
      bitrate: string
    }[]
    type?: string
  }
}

export function MediaAttachment(props: MediaAttachmentProps) {
  return (
    <>
      {props.onRemoveMediaComment ? (
        <RemovableItem
          onRemove={props.onRemoveMediaComment}
          screenReaderLabel={I18n.t('Remove media comment')}
          childrenAriaLabel={I18n.t('Media comment content')}
        >
          <MediaAttachmentPlayer {...props} />
        </RemovableItem>
      ) : (
        <MediaAttachmentPlayer {...props} />
      )}

      <div
        style={{
          width: '20rem',
          textOverflow: 'ellipsis',
          overflow: 'hidden',
          whiteSpace: 'nowrap',
          color: colors.ash,
        }}
      >
        {props.file.title}
      </div>
    </>
  )
}

type MediaAttachmentPlayerProps = Omit<MediaAttachmentProps, 'onRemoveMediaComment'>

const MediaAttachmentPlayer = (props: MediaAttachmentPlayerProps) => {
  const mediaSources = (): string[] => {
    if (props.file.src) {
      return [{label: I18n.t('Standard'), src: props.file.src, bitrate: '0'}]
    }

    return (
      props.file.mediaSources?.map(media => ({
        label: media.width + ' x ' + media.height,
        src: media.src,
        bitrate: media.bitrate,
      })) ?? []
    )
  }

  return (
    <View
      as="div"
      borderRadius="large"
      overflowX="hidden"
      overflowY="hidden"
      height="11.25rem"
      width="20rem"
      margin="small small small none"
      position="relative"
      shadow="above"
    >
      <CanvasMediaPlayer
        fluidHeight={true}
        resizeContainer={false}
        media_id={props.file.mediaID}
        media_sources={mediaSources()}
        media_tracks={props.file.mediaTracks}
        type={props.file.type}
        aria_label={props.file.title}
      />
    </View>
  )
}

export default MediaAttachment

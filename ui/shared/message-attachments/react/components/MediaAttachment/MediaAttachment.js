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
import PropTypes from 'prop-types'

import CanvasMediaPlayer from '@canvas/canvas-media-player'
import {RemovableItem} from '../RemovableItem/RemovableItem'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {colors} from '@instructure/canvas-theme'

const I18n = useI18nScope('conversations_2')

export function MediaAttachment(props) {
  return (
    <>
      <RemovableItem
        onRemove={props.onRemoveMediaComment}
        screenReaderLabel={I18n.t('Remove media comment')}
        childrenAriaLabel={I18n.t('Media comment content')}
      >
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
            media_sources={[{label: props.file.title, src: props.file.src, type: props.file.type}]}
            media_tracks={props.file.mediaTracks}
            type={props.file.type}
            aria_label={props.file.title}
          />
        </View>
      </RemovableItem>

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

MediaAttachment.propTypes = {
  onRemoveMediaComment: PropTypes.func.isRequired,
  file: PropTypes.shape({
    mediaID: PropTypes.string.isRequired,
    mediaTracks: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        src: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired,
        type: PropTypes.string.isRequired,
        language: PropTypes.string.isRequired,
      })
    ),
    title: PropTypes.string.isRequired,
    src: PropTypes.string.isRequired,
    type: PropTypes.oneOf(['audio', 'video']).isRequired,
  }).isRequired,
}

export default MediaAttachment

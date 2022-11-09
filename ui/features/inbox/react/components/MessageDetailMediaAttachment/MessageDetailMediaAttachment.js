/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {IconAttachMediaLine} from '@instructure/ui-icons'
import {MediaComment} from '../../../graphql/MediaComment'
import {MediaPlayer} from '@instructure/ui-media-player'
import {View} from '@instructure/ui-view'

export const MessageDetailMediaAttachment = props => {
  const [open, setOpen] = useState(false)

  const getAutoTrack = tracks => {
    if (!ENV.auto_show_cc) return undefined
    if (!tracks) return undefined
    let locale = ENV.locale || document.documentElement.getAttribute('lang') || 'en'
    // look for an exact match
    let auto_track = tracks.find(t => t.locale === locale)
    if (!auto_track) {
      // look for an exact match to the de-regionalized user locale
      locale = locale.replace(/-.*/, '')
      auto_track = tracks.find(t => t.locale === locale)
      if (!auto_track) {
        // look for any match to de-regionalized tracks
        auto_track = tracks.find(t => t.locale.replace(/-.*/, '') === locale)
      }
    }
    return auto_track?.locale
  }

  const mediaSources = props.mediaComment.mediaSources.map(source => ({
    ...source,
    label: `${source.width}x${source.height}`,
  }))

  const mediaTracks = props.mediaComment.mediaTracks.map(track => ({
    id: track._id,
    src: `/media_objects/${props.mediaComment._id}/media_tracks/${track._id}`,
    label: track.locale,
    type: track.kind,
    language: track.locale,
  }))

  return (
    <Flex direction="column">
      <Flex.Item>
        <Link isWithinText={false} as="button" onClick={() => setOpen(!open)} margin="xx-small">
          <IconAttachMediaLine /> {props.mediaComment.title}
        </Link>
      </Flex.Item>
      {open && (
        <Flex.Item>
          <View as="div" padding="x-small 0" data-testid="media-player">
            <MediaPlayer
              tracks={mediaTracks}
              sources={mediaSources}
              captionPosition="bottom"
              autoShowCaption={getAutoTrack(props.mediaComment.mediaTracks)}
            />
          </View>
        </Flex.Item>
      )}
    </Flex>
  )
}

MessageDetailMediaAttachment.propTypes = {
  mediaComment: MediaComment.shape,
}

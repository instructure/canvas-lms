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

import {MediaInfo, MediaTrack} from "@canvas/canvas-studio-player/react/types";
import {captionLanguageForLocale} from "@instructure/canvas-media";
import {Flex} from "@instructure/ui-flex";
import {Heading} from "@instructure/ui-heading";
import {Text} from "@instructure/ui-text";
import {useScope as createI18nScope} from '@canvas/i18n'
import React from "react";

const I18n = createI18nScope('files_v2')

const renderMediaTracks = (media_tracks: MediaTrack[]) => {
  return media_tracks.map((caption: MediaTrack) => (
    <p key={caption.id}>{captionLanguageForLocale(caption.locale)}</p>
  ))
}
const MediaFileInfo = ({mediaInfo}: {mediaInfo: MediaInfo}) => {
  if (!mediaInfo || !mediaInfo.can_add_captions) { return null }

  return (
    <Flex direction="column" gap="small">
      <Heading margin="large 0">{I18n.t('Video Options')}</Heading>
      <Flex.Item>
        {
          mediaInfo.media_tracks && (<>
            <Text weight="bold">{I18n.t('Closed Captions/Subtitles')}</Text>
            <br/>
            {
              mediaInfo.media_tracks.length > 0 ? renderMediaTracks(mediaInfo.media_tracks) : I18n.t('None')
            }
          </>)
        }
      </Flex.Item>
    </Flex>
  )
}

export default MediaFileInfo

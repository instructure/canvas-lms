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
import {captionLanguageForLocale} from '@instructure/canvas-media'
import {Flex} from '@instructure/ui-flex'

import {MediaTrack} from '@canvas/canvas-studio-player/react/types'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import {useDeleteCaption} from './useDeleteCaption'
import {showFlashError} from '../../../../../../shared/alerts/react/FlashAlert'

const I18n = createI18nScope('files_v2')

export interface MediaTrackListProps {
  mediaTracks: MediaTrack[]
  attachmentId: string
}

export const MediaTrackList = ({mediaTracks, attachmentId}: MediaTrackListProps) => {
  const deleteCaptionMutation = useDeleteCaption({attachmentId})

  const handleDelete = async (trackId: string) => {
    try {
      await deleteCaptionMutation.mutateAsync(trackId)
    } catch (_e) {
      showFlashError(I18n.t('An error occurred while deleting the caption.'))()
    }
  }

  return mediaTracks.map((track: MediaTrack) => (
    <Flex key={track.id} justifyItems="space-between">
      <span>{captionLanguageForLocale(track.locale)}</span>
      <IconButton
        color="primary-inverse"
        screenReaderLabel={I18n.t('Delete caption')}
        onClick={() => handleDelete(track.id)}
        withBorder={false}
        withBackground={false}
      >
        <IconTrashLine />
      </IconButton>
    </Flex>
  ))
}

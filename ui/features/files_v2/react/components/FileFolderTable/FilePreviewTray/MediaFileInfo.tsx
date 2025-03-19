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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconPlusLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import type {File} from '../../../../interfaces/File'
import {MediaTrack} from '@canvas/canvas-studio-player/react/types'
import {UploadMediaTrackForm} from './UploadMediaTrackForm'
import LoadingIndicator from '../../../../../../shared/loading-indicator/react'
import {MediaTrackList} from './MediaTrackList'

const I18n = createI18nScope('files_v2')

export interface MediaFileInfoProps {
  attachment: File
  mediaTracks: MediaTrack[]
  isLoading: boolean
  canAddTracks: boolean
}

export const MediaFileInfo = ({
  attachment,
  mediaTracks,
  isLoading,
  canAddTracks,
}: MediaFileInfoProps) => {
  const [showUploadForm, setShowUploadForm] = useState(false)
  const showMediaFileInfo = canAddTracks && !attachment.restricted_by_master_course
  const existingLocales = mediaTracks.map((track: any) => track.locale)

  if (isLoading) {
    return (
      <Flex direction="column" gap="x-small">
        <Heading margin="large 0">{I18n.t('Media Options')}</Heading>
        <LoadingIndicator />
      </Flex>
    )
  }

  // canAddTracks is unknown until the response is complete
  if (!showMediaFileInfo) {
    return null
  }

  return (
    <Flex direction="column" gap="x-small">
      <Heading margin="large 0">{I18n.t('Media Options')}</Heading>

      <Text weight="bold">{I18n.t('Closed Captions/Subtitles')}</Text>

      {mediaTracks.length === 0 && (
        <Flex as="div" margin="0 0 x-small">
          {I18n.t('None')}
        </Flex>
      )}
      {showUploadForm ? (
        <UploadMediaTrackForm
          closeForm={() => setShowUploadForm(false)}
          attachmentId={attachment.id}
          existingLocales={existingLocales}
        />
      ) : (
        <CondensedButton
          renderIcon={<IconPlusLine size="x-small" />}
          color="primary-inverse"
          onClick={() => setShowUploadForm(true)}
        >
          {I18n.t('Add Captions/Subtitles')}
        </CondensedButton>
      )}
      {mediaTracks.length > 0 && (
        <>
          <hr />
          <MediaTrackList mediaTracks={mediaTracks} attachmentId={attachment.id} />
        </>
      )}
    </Flex>
  )
}

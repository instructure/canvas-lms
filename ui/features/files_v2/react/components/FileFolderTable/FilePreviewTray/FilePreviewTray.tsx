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

import React from 'react'
import {View} from '@instructure/ui-view'
import {CloseButton} from '@instructure/ui-buttons'
import CommonFileInfo from './CommonFileInfo'
import {MediaFileInfo} from './MediaFileInfo'
import type {File} from '../../../../interfaces/File'
import {MediaTrack} from '@canvas/canvas-studio-player/react/types'

export interface FilePreviewTrayProps {
  onDismiss: () => void
  item: File
  mediaTracks: MediaTrack[]
  isFetchingTracks: boolean
  canAddTracks: boolean
}

export const FilePreviewTray = ({
  onDismiss,
  item,
  mediaTracks,
  isFetchingTracks,
  canAddTracks,
}: FilePreviewTrayProps) => {
  return (
    <View
      as="div"
      background="primary-inverse"
      padding="medium"
      style={{minHeight: '100%'}}
      themeOverride={{
        backgroundPrimaryInverse: '#0F1316',
      }}
    >
      <CloseButton
        placement="end"
        offset="small"
        screenReaderLabel="Close"
        onClick={onDismiss}
        color="primary-inverse"
        data-testid="tray-close-button"
      />
      <CommonFileInfo item={item} />
      <MediaFileInfo
        attachment={item}
        mediaTracks={mediaTracks}
        key={item.id}
        isLoading={isFetchingTracks}
        canAddTracks={canAddTracks}
      />
    </View>
  )
}

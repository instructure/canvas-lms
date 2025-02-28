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
import {Flex} from '@instructure/ui-flex'
import {CloseButton} from '@instructure/ui-buttons'
import { MediaInfo } from '@canvas/canvas-studio-player/react/types'
import CommonFileInfo from "./CommonFileInfo";
import MediaFileInfo from "./MediaFileInfo";
import type {File} from "../../../../interfaces/File.ts"

interface FilePreviewTrayProps {
  onDismiss: () => void
  item: File
  mediaInfo: MediaInfo
}

const FilePreviewTray = ({onDismiss, item, mediaInfo}: FilePreviewTrayProps) => {
  return (
    <View as="div" padding="medium" background="primary-inverse" style={{minHeight: "100%"}}>
      <CloseButton
        placement="end"
        offset="small"
        screenReaderLabel="Close"
        onClick={onDismiss}
        color="primary-inverse"
        data-testid="tray-close-button"
      />
      <CommonFileInfo item={item} />
      <MediaFileInfo mediaInfo={mediaInfo}/>
    </View>
  )
}

export default FilePreviewTray

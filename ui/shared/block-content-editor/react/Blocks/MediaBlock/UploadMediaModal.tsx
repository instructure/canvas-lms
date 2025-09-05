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

import React, {useState} from 'react'
import getRCSProps from '@canvas/rce/getRCSProps'
import {UploadFile} from '@instructure/canvas-rce'
import {useScope as createI18nScope} from '@canvas/i18n'
import {handleMediaSubmit, panels, StoreProp, UploadData, UploadFilePanelIds} from './handleMedia'
import {MediaSources} from './types'

const I18n = createI18nScope('block_content_editor')

export function UploadMediaModal({
  open,
  onSubmit,
  onDismiss,
}: {
  open: boolean
  onSubmit: (data: MediaSources) => void
  onDismiss: () => void
}) {
  const [isUploading, setIsUploading] = useState(false)

  const handleSubmit = async (
    _editor: unknown,
    _accept: unknown,
    selectedPanel: UploadFilePanelIds,
    uploadData: UploadData,
    storeProps: StoreProp,
  ) => {
    setIsUploading(true)
    try {
      const result = await handleMediaSubmit(selectedPanel, uploadData, storeProps)
      onSubmit(result)
    } catch (error) {
      console.error('Media upload error:', error)
    } finally {
      setIsUploading(false)
    }
  }

  return open ? (
    <UploadFile
      accept={'video/*,audio/*'}
      trayProps={getRCSProps()!}
      label={I18n.t('Upload Media')}
      panels={panels as any}
      onDismiss={onDismiss}
      onSubmit={handleSubmit}
      canvasOrigin={window.location?.origin}
      uploading={isUploading}
    />
  ) : null
}

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

import getRCSProps from '@canvas/rce/getRCSProps'
import {UploadFile} from '@instructure/canvas-rce'
import {useState} from 'react'
import {handleImageSubmit, panels, StoreProp, UploadData, UploadFilePanelIds} from './handle-image'

export const ImageBlockUploadModal = (props: {
  open: boolean
  onSelected: (url: string, alt: string) => void
  onDismiss: () => void
}) => {
  const [isUploading, setIsUploading] = useState(false)

  const handleSubmit = async (
    _editor: unknown,
    _accept: unknown,
    selectedPanel: UploadFilePanelIds,
    uploadData: UploadData,
    storeProps: StoreProp,
  ) => {
    setIsUploading(true)
    const {url, altText} = await handleImageSubmit(selectedPanel, uploadData, storeProps)
    setIsUploading(false)
    props.onSelected(url, altText)
  }

  return props.open ? (
    <UploadFile
      accept={'image/*'}
      trayProps={getRCSProps()!}
      label={'Upload Image'}
      panels={panels as any}
      onDismiss={props.onDismiss}
      onSubmit={handleSubmit}
      canvasOrigin={window.location?.origin}
      uploading={isUploading}
    />
  ) : null
}

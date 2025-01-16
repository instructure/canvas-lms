/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useContext, useState} from 'react'
// @ts-expect-error
import {UploadFile, type UploadFilePanelId} from '@instructure/canvas-rce'
import {prepEmbedSrc} from '@instructure/canvas-rce/es/common/fileUrl'
import {RCSPropsContext} from '../../../Contexts'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('block-editor')

const handleImageSubmit = async (
  selectedPanel: UploadFilePanelId,
  uploadData: UploadData,
  storeProps?: StoreProp,
) => {
  const {altText, isDecorativeImage, displayAs} = uploadData?.imageOptions || {}
  let url

  switch (selectedPanel) {
    case 'COMPUTER': {
      const {theFile} = uploadData
      const fileMetaData = {
        parentFolderId: 'media',
        name: theFile.name,
        size: theFile.size,
        contentType: theFile.type,
        domObject: theFile,
        altText,
        isDecorativeImage,
        displayAs,
        usageRights:
          uploadData?.usageRights?.usageRight === 'choose' ? undefined : uploadData?.usageRights,
      }
      const tabContext = 'documents'
      try {
        const result = await storeProps?.startMediaUpload(tabContext, fileMetaData)
        url = prepEmbedSrc(result.href || result.url)
      } catch (_err) {
        url = ''
        showFlashError(I18n.t('Failed to upload the image, please try again'))()
      }
      break
    }
    case 'URL': {
      url = uploadData.fileUrl
      break
    }
    default:
      if (uploadData?.fileUrl) {
        url = prepEmbedSrc(uploadData.fileUrl)
      } else {
        throw new Error('Selected Panel is invalid') // Should never get here
      }
  }
  return url
}

interface AddImageModalProps {
  open: boolean
  onSubmit: (url: string, alt: string) => void
  onDismiss: () => void
  accept?: string
  panels?: UploadFilePanelId[]
  title?: string
}

export const AddImageModal = ({
  open,
  onSubmit,
  onDismiss,
  accept = 'image/*',
  panels,
  title,
}: AddImageModalProps) => {
  const trayProps = useContext(RCSPropsContext)

  const [uploading, setUploading] = useState(false)

  // UploadFile calls onSubmit with 5 separate args, not a destructed object
  // so even though we never use editor/accept, we must include them
  const handleSubmit = async (
    _editor: any,
    _accept: string,
    selectedPanel: UploadFilePanelId,
    uploadData: UploadData,
    storeProps: StoreProp,
  ) => {
    setUploading(true)
    const url = await handleImageSubmit(selectedPanel, uploadData, storeProps)
    setUploading(false)
    const alt = uploadData?.imageOptions?.isDecorativeImage
      ? ''
      : uploadData?.imageOptions?.altText || ''
    onSubmit(url, alt)
  }

  const defaultPanels: UploadFilePanelId[] = ['COMPUTER', 'URL', 'course_images', 'user_images']

  const modalPanels = panels || defaultPanels
  const label = title || I18n.t('Upload Image')

  return open ? (
    <UploadFile
      accept={accept}
      trayProps={trayProps}
      label={label}
      panels={modalPanels}
      onDismiss={onDismiss}
      onSubmit={handleSubmit}
      forBlockEditorUse={true}
      canvasOrigin={trayProps?.canvasOrigin}
      uploading={uploading}
    />
  ) : null
}

type UploadData = {
  theFile: File
  fileUrl: string
  usageRights: {
    usageRight: string
    ccLicense: string
    copyrightHolder: string
  }
  imageOptions: {
    altText: string
    isDecorativeImage: boolean
    displayAs: string
  }
}

type StoreProp = {
  startMediaUpload: Function
}

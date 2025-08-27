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

import {prepEmbedSrc} from '@instructure/canvas-rce/es/common/fileUrl'

export type UploadData = {
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

export type StoreProp = {
  startMediaUpload: Function
}

export const panels = ['COMPUTER', 'URL', 'course_images', 'user_images'] as const
export type UploadFilePanelIds = (typeof panels)[number]

const handleComputerUpload = async (uploadData: UploadData, storeProps: StoreProp) => {
  const {
    theFile,
    imageOptions: {altText, isDecorativeImage, displayAs},
  } = uploadData
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

  try {
    const tabContext = 'documents'
    const result = await storeProps?.startMediaUpload(tabContext, fileMetaData)
    return prepEmbedSrc(result.href || result.url) as string
  } catch (_err) {
    throw new Error('Failed to upload the image, please try again')
  }
}

export const handleImageSubmit = async (
  selectedPanel: UploadFilePanelIds,
  uploadData: UploadData,
  storeProps: StoreProp,
) => {
  const altText = getAltText(uploadData)
  const url = await getUrl(selectedPanel, uploadData, storeProps)
  return {url, altText}
}

const getAltText = (uploadData: UploadData) => {
  return uploadData?.imageOptions?.isDecorativeImage ? '' : uploadData?.imageOptions?.altText || ''
}

const getUrl = async (
  selectedPanel: UploadFilePanelIds,
  uploadData: UploadData,
  storeProps: StoreProp,
) => {
  switch (selectedPanel) {
    case 'COMPUTER': {
      return await handleComputerUpload(uploadData, storeProps)
    }
    case 'URL': {
      return uploadData.fileUrl
    }
    default: {
      if (uploadData?.fileUrl) {
        return prepEmbedSrc(uploadData.fileUrl) as string
      }
      throw new Error('Selected Panel is invalid')
    }
  }
}

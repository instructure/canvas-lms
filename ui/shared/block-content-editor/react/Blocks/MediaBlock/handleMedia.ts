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
import saveMediaRecording from '@instructure/canvas-media/es/saveMediaRecording'

export type StoreProp = {
  jwt: string
  host: string
  contextId: string
  contextType: string
}
export type UploadData = {
  theFile?: File
  fileUrl?: string
}
export const panels = ['COMPUTER', 'URL', 'course_media', 'user_media']
export type UploadFilePanelIds = (typeof panels)[number]

const progressCallBack = () => {}

const handleComputerUpload = async (uploadData: UploadData, storeProps: StoreProp) => {
  const {theFile} = uploadData

  if (!theFile) {
    throw new Error('No file provided for upload')
  }

  try {
    const {jwt, host, contextId, contextType} = storeProps

    const rcsConfig = {
      contextId,
      contextType,
      origin: host,
      headers: {Authorization: `Bearer ${jwt}`},
    }

    const result = await new Promise<any>((resolve, reject) => {
      const doneCallback = (err: any, data: any) => (err ? reject(err) : resolve(data))
      saveMediaRecording(theFile, rcsConfig, doneCallback, progressCallBack)
    })
    if (!result.mediaObject?.embedded_iframe_url) {
      throw new Error('No iframe media URL given')
    }
    return result.mediaObject.embedded_iframe_url
  } catch (error) {
    console.error('Media upload error details:', error)
    throw new Error('Failed to upload the media file, please try again')
  }
}

export const handleMediaSubmit = async (
  selectedPanel: UploadFilePanelIds,
  uploadData: UploadData,
  storeProps: StoreProp,
) => {
  switch (selectedPanel) {
    case 'COMPUTER': {
      return await handleComputerUpload(uploadData, storeProps)
    }
    default: {
      if (!uploadData.fileUrl) {
        throw new Error('No iframe media URL given')
      }
      return uploadData.fileUrl
    }
  }
}

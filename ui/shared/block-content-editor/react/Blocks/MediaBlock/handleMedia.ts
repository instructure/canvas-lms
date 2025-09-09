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
import {MediaSources} from './types'

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
export const panels = ['COMPUTER', 'VIDEO_URL', 'course_media', 'user_media']
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
    return result.mediaObject.media_object.media_id
  } catch (error) {
    console.error('Media upload error details:', error)
    throw new Error('Failed to upload the media file, please try again')
  }
}

const handleCourseMediaUpload = async (uploadData: UploadData) => {
  const {fileUrl} = uploadData
  const attachment_id = fileUrl?.split('/').pop()
  if (!attachment_id) {
    throw new Error('No attachment ID found in the file URL')
  }

  return attachment_id
}

export const handleMediaSubmit = async (
  selectedPanel: UploadFilePanelIds,
  uploadData: UploadData,
  storeProps: StoreProp,
): Promise<MediaSources> => {
  switch (selectedPanel) {
    case 'COMPUTER': {
      const mediaId = await handleComputerUpload(uploadData, storeProps)
      return {mediaId}
    }
    case 'user_media':
    case 'course_media': {
      const attachment_id = await handleCourseMediaUpload(uploadData)
      return {attachment_id}
    }
    default: {
      if (!uploadData.fileUrl) {
        throw new Error('No iframe media URL given')
      }
      return {src: uploadData.fileUrl || ''}
    }
  }
}

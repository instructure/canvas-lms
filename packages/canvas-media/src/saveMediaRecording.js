/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import axios from 'axios'
import K5Uploader from '@instructure/k5uploader'

export const VIDEO_SIZE_OPTIONS = {height: '432px', width: '768px'}
const STARTING_PROGRESS_VALUE = 33

function generateUploadOptions(mediatypes, sessionData) {
  const sessionDataCopy = JSON.parse(JSON.stringify(sessionData))
  delete sessionDataCopy.kaltura_setting
  return {
    kaltura_session: sessionDataCopy,
    allowedMediaTypes: mediatypes,
    uploadUrl: sessionData.kaltura_setting.uploadUrl,
    entryUrl: sessionData.kaltura_setting.entryUrl,
    uiconfUrl: sessionData.kaltura_setting.uiconfUrl,
    entryDefaults: {
      partnerData: sessionData.kaltura_setting.partner_data
    }
  }
}

function addUploaderReadyEventListeners(uploader, file) {
  uploader.addEventListener('K5.ready', () => {
    uploader.uploadFile(file)
  })
}

function addUploaderProgressEventListeners(uploader, onProgress) {
  uploader.addEventListener('K5.progress', progress => {
    const percentUploaded = Math.round(progress.loaded / progress.total) * STARTING_PROGRESS_VALUE
    onProgress(STARTING_PROGRESS_VALUE + percentUploaded)
  })
}

function addUploaderFileErrorEventListeners(uploader, done, file) {
  uploader.addEventListener('K5.fileError', error => {
    uploader.destroy()
    doDone(done, error, {uploadedFile: file})
  })
}

function addUploaderFileCompleteEventListeners(uploader, context, file, done, onProgress) {
  uploader.addEventListener('K5.complete', async mediaServerMediaObject => {
    mediaServerMediaObject.contextCode = `${context.contextType}_${context.contextId}`
    mediaServerMediaObject.type = `${context.contextType}_${context.contextId}`

    const body = {
      id: mediaServerMediaObject.entryId,
      type:
        {2: 'image', 5: 'audio'}[mediaServerMediaObject.mediaType] ||
        mediaServerMediaObject.type.includes('audio')
          ? 'audio'
          : 'video',
      context_code: mediaServerMediaObject.contextCode,
      title: file.name,
      user_entered_title: file.name
    }

    try {
      const config = {
        onUploadProgress: progressEvent => {
          const startingValue = 2 * STARTING_PROGRESS_VALUE
          const percentUploaded =
            Math.round(progressEvent.loaded / progressEvent.total) * (STARTING_PROGRESS_VALUE + 1)
          if (onProgress) {
            onProgress(startingValue + percentUploaded)
          }
        }
      }
      const canvasMediaObject = await axios.post('/api/v1/media_objects', body, config)
      uploader.destroy()
      doDone(done, null, {mediaObject: canvasMediaObject.data, uploadedFile: file})
    } catch (ex) {
      uploader.destroy()
      doDone(done, ex, {uploadedFile: file})
    }
  })
}

export default async function saveMediaRecording(file, rcsConfig, done, onProgress) {
  try {
    window.addEventListener('beforeunload', handleUnloadWhileUploading)

    // this works w/o rcsConfig.origin and headers because the api path
    // is the same for the RCS as Canvas. Doing it this way means
    // saveMediaRecording can be called w/o having to import anything
    // from @instructure/canvas-rce
    const mediaServerSession = await axios({
      method: 'POST',
      url: `${rcsConfig.origin || ''}/api/v1/services/kaltura_session?include_upload_config=1`,
      headers: rcsConfig.headers
    })
    if (onProgress) {
      onProgress(STARTING_PROGRESS_VALUE)
    }
    const session = generateUploadOptions(
      ['video', 'audio', 'webm', 'video/webm', 'audio/webm'],
      mediaServerSession.data
    )
    const k5UploaderSession = new K5Uploader(session)
    addUploaderReadyEventListeners(k5UploaderSession, file)
    if (onProgress) {
      addUploaderProgressEventListeners(k5UploaderSession, onProgress)
    }
    addUploaderFileErrorEventListeners(k5UploaderSession, done, file)
    addUploaderFileCompleteEventListeners(k5UploaderSession, rcsConfig, file, done, onProgress)
    return k5UploaderSession
  } catch (err) {
    doDone(done, err, {uploadedFile: file})
  }
}

/*
 * @media_object_id: id of the media_object we're assigning CC to
 * @subtitles: [{locale: string locale, file: JS File object}]
 * @rcsConfig: {origin, headers, method} where method=PUT for update or POST for create
 */
export async function saveClosedCaptions(media_object_id, subtitles, rcsConfig) {
  // read all the subtitle files' contents
  const file_promises = []
  subtitles.forEach(st => {
    if (st.isNew) {
      const p = new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = function (e) {
          resolve({locale: st.locale, content: e.target.result})
        }
        reader.onerror = function (e) {
          e.target.abort()
          reject(e.target.error || e)
        }
        reader.readAsText(st.file)
      })
      file_promises.push(p)
    } else {
      file_promises.push(Promise.resolve({locale: st.locale}))
    }
  })

  // once all the promises from reading the subtitles' files
  // have resolved, PUT/POST the resulting subtitle objects to the RCS
  // when that completes, the update_promise will resolve
  const update_promise = new Promise((resolve, reject) => {
    Promise.all(file_promises)
      .then(closed_captions => {
        const url = rcsConfig.origin
          ? `${rcsConfig.origin}/api/media_objects/${media_object_id}/media_tracks`
          : `/api/v1/media_objects/${media_object_id}/media_tracks`
        axios({
          method: rcsConfig.method || 'PUT',
          url,
          headers: rcsConfig.headers,
          data: closed_captions
        })
          .then(resolve)
          .catch(e => {
            reject(e)
          })
      })
      .catch(e => reject(e))
  })
  return update_promise
}

function doDone(done, ...rest) {
  window.removeEventListener('beforeunload', handleUnloadWhileUploading)
  done(...rest)
}

function handleUnloadWhileUploading(e) {
  e.preventDefault()
  e.returnValue = ''
}

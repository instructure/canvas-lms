//
// Copyright (C) 2024 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {K5Uploader} from '@instructure/k5uploader'
import {useScope as createI18nScope} from '@canvas/i18n'
import KalturaSessionLoader from '@canvas/media-comments/jquery/kaltura_session_loader'
import $ from 'jquery'

const I18n = createI18nScope('sg_uploader')

export default class SGUploader {
  constructor() {
    this.kSession = new KalturaSessionLoader()
    this.loadSession()
  }

  loadSession() {
    return this.kSession.loadSession('/api/v1/services/kaltura_session', () => {})
  }

  onReady() {}

  getKs() {
    return this.kSession.kalturaSession.ks
  }

  getUid() {
    return this.kSession.kalturaSession.uid
  }

  doUploadByFile = (
    inputFile,
    submissionId,
    groupComment,
    attempt,
    mutationCallback,
    allowedMedia = ['video', 'audio', 'webm', 'video/webm', 'audio/webm'],
  ) => {
    this.file = inputFile
    if (this.uploader) this.resetUploader()
    const session = this.kSession.generateUploadOptions(allowedMedia)
    this.uploader = new K5Uploader(session)
    this.uploader.addEventListener('K5.fileError', this.onFileError)
    this.uploader.addEventListener('K5.complete', e =>
      this.onUploadComplete(e, submissionId, groupComment, attempt, mutationCallback),
    )
    return this.uploader.addEventListener('K5.ready', this.onUploaderReady)
  }

  onFileError = e => {
    const {
      allowedMediaTypes,
      file: {type: fileType},
    } = e
    alert(
      I18n.t(
        'File type %{fileType} not compatible with selected media type: %{allowedMediaTypes}.',
        {fileType, allowedMediaTypes},
      ),
    )
  }

  onUploadComplete = (e, submissionId, groupComment, attempt, mutationCallback) => {
    this.resetUploader()
    if (!((e.title != null ? e.title.length : undefined) > 0)) {
      e.title = this.file.name
    }
    this.addEntry(e, this.file.type.includes('audio'), resp => {
      const mediaCommentId = resp.media_object?.media_id
      const mediaCommentType = resp.media_object?.media_type

      if (typeof mutationCallback === 'function' && mediaCommentId && mediaCommentType) {
        mutationCallback(submissionId, groupComment, attempt, mediaCommentType, mediaCommentId)
      }
    })
  }

  onUploaderReady = () => {
    return this.uploader.uploadFile(this.file)
  }

  resetUploader = () => {
    this.uploader.removeEventListener('K5.fileError', this.onFileError)
    this.uploader.removeEventListener('K5.complete', this.onUploadComplete)
    this.uploader.removeEventListener('K5.ready', this.onUploaderReady)
    return this.uploader.destroy()
  }

  addEntry = (entry, isAudioFile, callback) => {
    const contextCode =
      ENV.media_comment_asset_string || ENV.context_asset_string || 'user_' + ENV.current_user_id
    const mediaType = {2: 'image', 5: 'audio'}[entry.mediaType] || isAudioFile ? 'audio' : 'video'
    if (contextCode) {
      $.ajaxJSON(
        '/media_objects',
        'POST',
        {
          id: entry.entryId,
          type: mediaType,
          context_code: contextCode,
          title: entry.title,
          user_entered_title: entry.userTitle,
        },
        resp => {
          if (typeof callback === 'function') {
            callback(resp)
          }
        },
      )
    }
  }
}

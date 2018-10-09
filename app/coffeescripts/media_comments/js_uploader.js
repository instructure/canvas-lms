//
// Copyright (C) 2014 - present Instructure, Inc.
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

import DialogManager from '../media_comments/dialog_manager'
import CommentUiLoader from '../media_comments/comment_ui_loader'
import K5Uploader from 'bower/k5uploader/k5uploader'
import UploadViewManager from '../media_comments/upload_view_manager'
import KalturaSessionLoader from '../media_comments/kaltura_session_loader'
import FileInputManager from '../media_comments/file_input_manager'

/*
   * Creates and Mediates between various upload ui and actors
   */
export default class JsUploader {
  constructor() {
    this.initialize = this.initialize.bind(this)
    this.doUpload = this.doUpload.bind(this)
    this.doUploadByFile = this.doUploadByFile.bind(this)
    this.onFileError = this.onFileError.bind(this)
    this.onUploadComplete = this.onUploadComplete.bind(this)
    this.onUploaderReady = this.onUploaderReady.bind(this)
    this.resetUploader = this.resetUploader.bind(this)
    this.dialogManager = new DialogManager()
    this.commentUiLoader = new CommentUiLoader()
    this.kSession = new KalturaSessionLoader()
    this.uploadViewManager = new UploadViewManager()
    this.fileInputManager = new FileInputManager()
    this.dialogManager.initialize()
    this.loadSession()
  }

  loadSession() {
    return this.kSession.loadSession(
      '/api/v1/services/kaltura_session',
      this.initialize,
      this.uploadViewManager.showConfigError
    )
  }

  onReady() {}
  // override this

  initialize(mediaType, opts) {
    return this.commentUiLoader.loadTabs(html => {
      this.onReady()
      this.dialogManager.displayContent(html)
      this.dialogManager.activateTabs()
      this.dialogManager.mediaReady(mediaType, opts)
      this.createNeededFields()
      return this.bindEvents()
    })
  }

  getKs() {
    return this.kSession.kalturaSession.ks
  }

  getUid() {
    return this.kSession.kalturaSession.uid
  }

  bindEvents() {
    this.fileInputManager.setUpInputTrigger('#audio_upload_holder', ['audio'])
    return this.fileInputManager.setUpInputTrigger('#video_upload_holder', ['video'])
  }

  createNeededFields() {
    return this.fileInputManager.resetFileInput(this.doUpload)
  }

  doUpload() {
    this.file = this.fileInputManager.getSelectedFile()
    if (this.uploader) this.resetUploader()
    const session = this.kSession.generateUploadOptions(this.fileInputManager.allowedMedia)
    this.uploader = new K5Uploader(session)
    this.uploader.addEventListener('K5.fileError', this.onFileError)
    this.uploader.addEventListener('K5.complete', this.onUploadComplete)
    this.uploader.addEventListener('K5.ready', this.onUploaderReady)

    this.uploadViewManager = new UploadViewManager()
    return this.uploadViewManager.monitorUpload(
      this.uploader,
      this.fileInputManager.allowedMedia,
      this.file
    )
  }

  doUploadByFile(inputFile) {
    this.file = inputFile
    if (this.uploader) {
      this.resetUploader()
    }
    const session = this.kSession.generateUploadOptions(['video', 'audio', 'webm'])
    this.uploader = new K5Uploader(session)
    this.uploader.addEventListener('K5.fileError', this.onFileError)
    this.uploader.addEventListener('K5.complete', this.onUploadComplete)
    return this.uploader.addEventListener('K5.ready', this.onUploaderReady)
  }

  onFileError() {
    return this.createNeededFields()
  }

  onUploadComplete(e) {
    this.resetUploader()
    if (!((e.title != null ? e.title.length : undefined) > 0)) {
      e.title = this.file.name
    }
    this.addEntry(e)
    return this.dialogManager.hide()
  }

  onUploaderReady() {
    return this.uploader.uploadFile(this.file)
  }

  resetUploader() {
    this.uploader.removeEventListener('K5.fileError', this.onFileError)
    this.uploader.removeEventListener('K5.complete', this.onUploadComplete)
    this.uploader.removeEventListener('K5.ready', this.onUploaderReady)
    return this.uploader.destroy()
  }
}

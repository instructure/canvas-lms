#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery',
  '../media_comments/dialog_manager',
  '../media_comments/comment_ui_loader',
  'bower/k5uploader/k5uploader',
  '../media_comments/upload_view_manager',
  '../media_comments/kaltura_session_loader',
  '../media_comments/file_input_manager'
], ($,
    DialogManager,
    CommentUiLoader,
    K5Uploader,
    UploadViewManager,
    KalturaSessionLoader,
    FileInputManager
) ->

  ###
  # Creates and Mediates between various upload ui and actors
  ###
  class JsUploader
    constructor: ->
      @dialogManager = new DialogManager()
      @commentUiLoader = new CommentUiLoader()
      @kSession = new KalturaSessionLoader()
      @uploadViewManager = new UploadViewManager()
      @fileInputManager = new FileInputManager()
      @dialogManager.initialize()
      @loadSession()

    loadSession: ->
      @kSession.loadSession('/api/v1/services/kaltura_session',
                            @initialize,
                            @uploadViewManager.showConfigError)

    onReady: ->
      # override this

    initialize: (mediaType, opts) =>
      @commentUiLoader.loadTabs (html) =>
        @onReady()
        @dialogManager.displayContent(html)
        @dialogManager.activateTabs()
        @dialogManager.mediaReady(mediaType, opts)
        @createNeededFields()
        @bindEvents()


    getKs: ->
      @kSession.kalturaSession.ks

    getUid: ->
      @kSession.kalturaSession.uid

    bindEvents: ->
      @fileInputManager.setUpInputTrigger('#audio_upload_holder', ['audio'])
      @fileInputManager.setUpInputTrigger('#video_upload_holder', ['video'])

    createNeededFields: ->
      @fileInputManager.resetFileInput(@doUpload)

    doUpload: =>
      @file = @fileInputManager.getSelectedFile()
      @resetUploader() if @uploader
      session = @kSession.generateUploadOptions(@fileInputManager.allowedMedia)
      @uploader = new K5Uploader(session)
      @uploader.addEventListener 'K5.fileError', @onFileError
      @uploader.addEventListener 'K5.complete', @onUploadComplete
      @uploader.addEventListener 'K5.ready', @onUploaderReady

      @uploadViewManager = new UploadViewManager()
      @uploadViewManager.monitorUpload(@uploader,
                                       @fileInputManager.allowedMedia,
                                       @file)

    onFileError: =>
      @createNeededFields()

    onUploadComplete: (e)=>
      @resetUploader()
      unless e.title?.length > 0
        e.title = @file.name
      @addEntry(e)
      @dialogManager.hide()

    onUploaderReady: =>
      @uploader.uploadFile(@file)

    resetUploader: =>
      @uploader.removeEventListener 'K5.fileError', @onFileError
      @uploader.removeEventListener 'K5.complete', @onUploadComplete
      @uploader.removeEventListener 'K5.ready', @onUploaderReady
      @uploader.destroy()

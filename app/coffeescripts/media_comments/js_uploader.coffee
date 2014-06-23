define [
  'jquery',
  'i18n!media_comments',
  'compiled/media_comments/dialog_manager',
  'compiled/media_comments/comment_ui_loader',
  'bower/k5uploader/k5uploader',
  'compiled/media_comments/upload_view_manager',
  'compiled/media_comments/kaltura_session_loader',
  'compiled/media_comments/file_input_manager'
], ($,
    I18n,
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
      @addEntry(e)
      @dialogManager.hide()

    onUploaderReady: =>
      @uploader.uploadFile(@file)

    resetUploader: =>
      @uploader.removeEventListener 'K5.fileError', @onFileError
      @uploader.removeEventListener 'K5.complete', @onUploadComplete
      @uploader.removeEventListener 'K5.ready', @onUploaderReady
      @uploader.destroy()

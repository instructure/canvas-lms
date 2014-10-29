define [
  'underscore'
  './FileUploader'
  './ZipUploader'
], (_, FileUploader, ZipUploader) ->

  class UploadQueue
    _uploading: false
    _queue: []

    length: ->
      @_queue.length

    flush: ->
      @_queue = []

    getAllUploaders: ->
      all = @_queue.slice()
      all = all.concat(@currentUploader) if @currentUploader
      all.reverse()

    getCurrentUploader: ->
      @currentUploader

    onChange: ->
      #noop, set by components who care about it

    onUploadProgress: (percent, file) =>
      @onChange()

    createUploader: (fileOptions, folder, contextId, contextType) ->
      uploader = if fileOptions.expandZip
        new ZipUploader(fileOptions, folder, contextId, contextType)
      else
        new FileUploader(fileOptions, folder)
      uploader.onProgress = @onUploadProgress
      uploader.cancel = =>
        uploader._xhr?.abort()
        @_queue = _.without(@_queue, uploader)
        @onChange()

      uploader

    enqueue: (fileOptions, folder, contextId, contextType) ->
      uploader = @createUploader(fileOptions, folder, contextId, contextType)
      @_queue.push uploader
      @attemptNextUpload()

    dequeue: ->
      firstNonErroredUpload = _.find @_queue, (upload) -> !upload.error
      @_queue = _.without(@_queue, firstNonErroredUpload)
      firstNonErroredUpload

    attemptNextUpload: ->
      @onChange()
      return if @_uploading || @_queue.length == 0
      @currentUploader = uploader = @dequeue()
      if uploader
        @onChange()
        @_uploading = true

        promise = uploader.upload()
        promise.fail (failReason) =>
          # put it back in the queue unless the user aborted it
          unless failReason is 'user_aborted_upload'
            @_queue.unshift(uploader)

        promise.always =>
          @_uploading = false
          @currentUploader = null
          @onChange()
          @attemptNextUpload()

  new UploadQueue()

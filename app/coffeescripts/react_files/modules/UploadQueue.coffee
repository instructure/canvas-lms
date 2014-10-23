define [
  './FileUploader'
  './ZipUploader'
], (FileUploader, ZipUploader) ->

  class UploadQueue
    _uploading: false
    _queue: []

    length: ->
      @_queue.length

    flush: ->
      @_queue = []

    getAllUploaders: ->
      all = @_queue.slice()
      all = all.concat(@currentUploader) if !!@currentUploader
      all.reverse()

    getCurrentUploader: ->
      @currentUploader

    onChange: ->
      #noop, set by components who care about it

    onUploadProgress: (percent, file) =>
      @onChange()

    createUploader: (fileOptions, folder, contextId, contextType) ->
      if fileOptions.expandZip
        f = new ZipUploader(fileOptions, folder, contextId, contextType)
      else
        f = new FileUploader(fileOptions, folder)
      f.onProgress = @onUploadProgress
      f

    enqueue: (fileOptions, folder, contextId, contextType) ->
      uploader = @createUploader(fileOptions, folder, contextId, contextType)
      @_queue.push uploader
      @attemptNextUpload()

    dequeue: ->
      @_queue.shift()

    attemptNextUpload: ->
      @onChange()
      return if @_uploading || @_queue.length == 0
      @currentUploader = @dequeue()
      if @currentUploader
        @onChange()
        @_uploading = true
        @currentUploader.upload().then =>
          @_uploading = false
          @currentUploader = null
          @onChange()
          @attemptNextUpload()

  new UploadQueue()

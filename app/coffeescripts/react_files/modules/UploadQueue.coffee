define [
  './FileUploader'
], (FileUploader) ->

  class UploadQueue
    _uploading: false
    _queue: []
    _currentUploader: null

    length: ->
      @_queue.length

    flush: ->
      @_queue = []

    onUploadProgress: (percent, file) =>
      # TODO: hook this up to UI CNVS-12658
      console.log("#{file.name}: #{percent} %")

    createUploader: (fileOptions, folder) ->
      f = new FileUploader(fileOptions, folder)
      f.onProgress = @onUploadProgress
      @_currentUploader = f
      f

    enqueue: (fileOptions, folder) ->
      uploader = @createUploader(fileOptions, folder)
      @_queue.push uploader
      @attemptNextUpload()

    dequeue: ->
      @_queue.shift()

    attemptNextUpload: ->
      return if @_uploading || @_queue.length == 0
      fileUploader = @dequeue()
      if fileUploader
        @_uploading = true
        fileUploader.upload().then =>
          @_uploading = false
          @attemptNextUpload()

  new UploadQueue()

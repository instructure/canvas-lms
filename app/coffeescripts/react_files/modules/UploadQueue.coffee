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

    createUploader: (file, folder) ->
      f = new FileUploader(file, folder)
      f.onProgress = @onUploadProgress
      @_currentUploader = f
      f

    enqueue: (file, folder) ->
      uploader = @createUploader(file, folder)
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

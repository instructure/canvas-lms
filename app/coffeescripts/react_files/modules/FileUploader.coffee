define [
  'jquery'
  'compiled/models/File'
  'compiled/collections/FilesCollection'
  'jquery.ajaxJSON'
], ($, BBFile, FilesCollection) ->

  class FileUploader

    constructor: (fileOptions, folder) ->
      @file = fileOptions.file
      @options = fileOptions
      @folder = folder

    onProgress: (percentComplete, file) ->
      #noop will be set up a level

    onError: (e) ->
      #noop will be set up a level

    createFormData: (data) ->
      formData = new FormData()
      Object.keys(data).forEach (key) ->
        formData.append(key, data[key])
      formData.append('file', @file)
      formData

    # kickoff / preflight upload process
    upload: ->
      deferred = $.Deferred()
      params =
        name: @options.name || @file.name
        size: @file.size
        content_type: @file.type
        on_duplicate: @options.dup || 'rename'
        parent_folder_id: @folder.id

      preflightUrl = "/api/v1/folders/#{@folder.id}/files"
      $.ajaxJSON preflightUrl, 'POST', params, (data) =>
        @_actualUpload(data, deferred)
      deferred

    #actual upload based on kickoff / preflight
    _actualUpload: (uploadData, deferred) ->

      xhr = new XMLHttpRequest
      xhr.upload.onprogress = @trackProgress
      xhr.open 'POST', uploadData.upload_url, true
      xhr.setRequestHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")

      formData = @createFormData(uploadData.upload_params)

      xhr.onload = (event) =>
        if event.target.status isnt 200
          return @handleContentError(event)
        response = $.parseJSON(event.target.response)
        f = @onUploadComplete(response)
        deferred.resolve(f)

      xhr.send formData

    onUploadComplete: (results) ->
      uploadedFile = new BBFile(results, 'no/url/needed/') #we've already done the upload, no preflight needed
      @folder.files.add(uploadedFile)

      #remove old version if it was just overwritten
      if @options.dup == 'overwrite'
        name = @options.name || @file.name
        previous = @folder.files.findWhere({display_name: name})
        @folder.files.remove(previous) if previous

      uploadedFile

    handleContentError: (e) =>
      @onError(e)

    trackProgress: (e) =>
      @onProgress((e.loaded / e.total), @file)

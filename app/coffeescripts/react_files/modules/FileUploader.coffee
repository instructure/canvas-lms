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

    createFormData: () ->
      data = @uploadData.upload_params
      formData = new FormData()
      Object.keys(data).forEach (key) ->
        formData.append(key, data[key])
      formData.append('file', @file)
      formData

    # kickoff / preflight upload process
    upload: ->
      @deferred = $.Deferred()
      params =
        name: @options.name || @file.name
        size: @file.size
        content_type: @file.type
        on_duplicate: @options.dup || 'rename'
        parent_folder_id: @folder.id
        no_redirect: true

      preflightUrl = "/api/v1/folders/#{@folder.id}/files"
      $.ajaxJSON preflightUrl, 'POST', params, (data) =>
        @uploadData = data
        @_actualUpload()
      @deferred

    #actual upload based on kickoff / preflight
    _actualUpload: () ->
      xhr = new XMLHttpRequest
      xhr.upload.addEventListener('progress', @trackProgress, false)
      xhr.upload.addEventListener('load', @onUploadPosted, false)
      xhr.open 'POST', @uploadData.upload_url, true
      xhr.send @createFormData()

    onUploadPosted: (uploadResults) =>
      $.getJSON(@uploadData.upload_params.success_url).then (results) =>
        f = @addFileToCollection(results)
        @deferred.resolve(f)

    addFileToCollection: (attrs) =>
      uploadedFile = new BBFile(attrs, 'no/url/needed/') #we've already done the upload, no preflight needed
      @folder.files.add(uploadedFile)

      #remove old version if it was just overwritten
      if @options.dup == 'overwrite'
        name = @options.name || @file.name
        previous = @folder.files.findWhere({display_name: name})
        @folder.files.remove(previous) if previous

      uploadedFile

    trackProgress: (e) =>
      @onProgress((e.loaded / e.total), @file)

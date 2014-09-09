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
      xhr.onload = @onUploadPosted
      xhr.open 'POST', @uploadData.upload_url, true
      xhr.send @createFormData()

    # when using s3 uploads you now need to manually hit the success_url
    # when using local uploads you have already been auto-redirected (even
    # though we requested no_redirect) to the succes_url at this point
    onUploadPosted: (event) =>
      url = @uploadData.upload_params.success_url
      if url
        $.getJSON(url).then (results) =>
          f = @addFileToCollection(results)
          @deferred.resolve(f)
      else
        results = $.parseJSON(event.target.response)
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
      @progress = (e.loaded/ e.total)
      @onProgress(@progress, @file)

    getProgress: ->
      @progress

    roundProgress: ->
      value = @getProgress() || 0
      Math.min(Math.round(value * 100), 100)

    getFileName: ->
      @options.name || @file.name

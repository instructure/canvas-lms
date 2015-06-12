define [
  'i18n!react_files'
  'jquery'
  'compiled/models/File'
  './BaseUploader'
  'jquery.ajaxJSON'
], (I18n, $, BBFile, BaseUploader) ->

  class FileUploader extends BaseUploader

    onUploadPosted: (event) =>
      if event.target.status >= 400
        @deferred.reject(event.target.status)
        return

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

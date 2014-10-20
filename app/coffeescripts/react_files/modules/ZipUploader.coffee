define [
  'jquery'
  './BaseUploader'
], ($, BaseUploader) ->

  # Zips that are to be expanded take a different upload workflow
  class ZipUploader extends BaseUploader
    constructor: (fileOptions, folder, contextId, contextType)->
      super fileOptions, folder
      @contextId = contextId
      @contextType = contextType
      @migrationProgress = 0

    createPreFlightParams: ->
      params =
        migration_type: 'zip_file_importer',
        settings:
          folder_id: @folder.id
        pre_attachment:
          name: @options.name || @file.name
          size: @file.size
          content_type: @file.type
          on_duplicate: @options.dup || 'rename'
          no_redirect: true

    getPreflightUrl: ->
      "/api/v1/#{@contextType}/#{@contextId}/content_migrations"

    onPreflightComplete: (data) =>
      @uploadData = data.pre_attachment
      @contentMigrationId = data.id
      @_actualUpload()

    onUploadPosted: (uploadResults) =>
      if (event.target.status >= 400)
        @deferred.reject()
        return

      url = @uploadData.upload_params.success_url
      if url
        $.getJSON(url).then (results) =>
          @getContentMigration()
      else
        results = $.parseJSON(event.target.response)
        @getContentMigration()

    # get the content migration when ready and use progress api to pull migration progress
    getContentMigration: =>
      $.getJSON("/api/v1/courses/#{@contextId}/content_migrations/#{@contentMigrationId}").then (results) =>
        if (!results.progress_url)
          setTimeout( =>
            @getContentMigration()
          , 500)
        else
          @pullMigrationProgress(results.progress_url)

    pullMigrationProgress: (url) =>
      $.getJSON(url).then (results) =>
        @trackMigrationProgress(results.completion || 0)
        if (results.workflow_state == 'failed')
          @deferred.reject()
        else if (results.completion < 100)
          setTimeout( =>
            @pullMigrationProgress(url)
          , 1000)
        else
          @onMigrationComplete()

    onMigrationComplete: ->
      # reload to get new files to appear
      promise = @folder.files.fetch({reset: true}).then =>
        @deferred.resolve()


    trackProgress: (e) =>
      @progress = (e.loaded/ e.total)
      @onProgress(@progress, @file)

    # migration progress is [0..100]
    trackMigrationProgress: (value) ->
      @migrationProgress = value / 100

    # progress counts for halp, migragtion for the other
    getProgress: ->
      (@progress + @migrationProgress) / 2

    roundProgress: ->
      value = @getProgress() || 0
      Math.min(Math.round(value * 100), 100)

    getFileName: ->
      @options.name || @file.name

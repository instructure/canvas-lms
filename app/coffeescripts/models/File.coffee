define [
  'jquery'
  'underscore'
  'Backbone'
  'jquery.ajaxJSON'
], ($, _, {Model}) ->

  # Simple model for creating an attachment in canvas
  #
  # Required stuff (or uploads won't work):
  #
  # 1. you need to pass a preflightUrl in the options
  # 2. at some point, you need to do: `model.set('file', <input>)`
  #    where <input> is the DOM node (not $-wrapped) of the file input
  class File extends Model

    url: ->
      if @isNew()
        # if it is new, fall back to Backbone's default behavior of using
        # the url of the collection this model belongs to.
        # aka: POST /api/v1/folders/:folder_id/files (to create)
        super
      else
        # for GET, PUT, and DELETE, our API expects "/api/v1/files/:file_id"
        # not "/api/v1/folders/:folder_id/files/:file_id" which is what
        # backbone would do by default.
        "/api/v1/files/#{@id}"

    initialize: (attributes, options) ->
      @preflightUrl = options.preflightUrl
      super

    save: (attrs = {}, options = {}) ->
      return super unless @get('file')
      @set attrs
      dfrd = $.Deferred()
      el = @get('file')
      name = (el.value || el.name).split(/[\/\\]/).pop()
      $.ajaxJSON @preflightUrl, 'POST', {name, on_duplicate: 'rename'},
        (data) =>
          @saveFrd data, dfrd, el, options
        (error) =>
          dfrd.reject(error)
          options.error?(error)
      dfrd

    saveFrd: (data, dfrd, el, options) =>
      # account for attachments wrapped in array per JSON API format
      if data.attachments && data.attachments[0]
        data = data.attachments[0]
      @uploadParams = data.upload_params
      @set @uploadParams
      el.name = data.file_param
      @url = -> data.upload_url
      Model::save.call this, null,
        multipart: true
        success: (data) =>
          dfrd.resolve(data)
          options.success?(data)
        error: (error) =>
          dfrd.reject(error)
          options.error?(error)

    toJSON: ->
      return super unless @get('file')
      _.pick(@attributes, 'file', _.keys(@uploadParams ? {})...)

    present: ->
      _.clone(@attributes)


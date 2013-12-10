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

    initialize: (attributes, options) ->
      @preflightUrl = options.preflightUrl
      super

    save: (attrs = {}, options = {}) ->
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
      _.pick(@attributes, 'file', _.keys(@uploadParams ? {})...)

    present: ->
      _.clone(@attributes)


define [
  'i18n!images'
  'jquery'
  'underscore'
  'compiled/models/File'
  'vendor/FileAPI/FileAPI.min'
], (I18n, $, _, File, FileAPI) ->

  class ImageFile extends File
    initialize: (attrs = {}, options = {}) ->

      @validations =
        maxSize: 32000
        width: 100
        height: 100
        types: ["jpeg", "png", "gif"]
      _.extend @validations, options.validations ? {}

      super

    loadFile: ->
      @valid = false

      # TODO: HTML5 when we drop IE9/Safari5
      file = FileAPI.getFiles(@get('file'))[0]
      return unless file
      dfrd = $.Deferred()
      FileAPI.filterFiles [file], (file, info) =>
        @validateFile(file, info, dfrd)
      , ->

      dfrd.then(
        (args...) =>
          @trigger 'loaded', args...
        (err) =>
          @error = err
          @trigger 'load_failed', err
      )

    validateFile: (file, info, dfrd) ->
      type = file.type.replace(/^image\//, '')
      if file.type is type
        dfrd.reject I18n.t("not_an_image", "Selected file is not an image")
      else if @validations.types? and @validations.types.indexOf(type) < 0
        dfrd.reject I18n.t("invalid_file_type", "Invalid file type %{type}. Allowed types include: %{type_list}", type: type, type_list: @validations.types.join(', '))
      else if @validations.width? and @validations.height? and (info.width isnt @validations.width or info.height isnt @validations.height)
        dfrd.reject I18n.t("invalid_dimensions", "Invalid image dimensions (got %{actual}, expected: %{expected})", actual: "#{info.width}x#{info.height}", expected: "#{@validations.width}x#{@validations.height}")
      else if @validations.maxSize and file.size > @validations.maxSize
        dfrd.reject I18n.t("invalid_file_size", "Image file size is too large (max %{max} bytes, got %{actual})", actual: file.size, max: @validations.maxSize)
      else if @validations.backgroundColor
        @validateBackground(file, info, dfrd)
      else
        @valid = true
        dfrd.resolve file, info

    validateBackground: (file, info, dfrd) ->
      FileAPI.Image(file).preview(file.width, file.height).get (err, canvas) =>
        if err
          dfrd.reject I18n.t("error_checking_color", "Error checking image color")
        else if _.any(@cornerColors(canvas), (color) => color isnt @validations.backgroundColor)
          dfrd.reject I18n.t("invalid_background_color", "Background color must be %{color}", color: @validations.backgroundColor)
        else
          @valid = true
          dfrd.resolve file, info

    cornerColors: (canvas) ->
      context = canvas.getContext('2d')
      [
        @rgbToHex context.getImageData(0, 0, 1, 1).data...
        @rgbToHex context.getImageData(canvas.width - 1, 0, 1, 1).data...
        @rgbToHex context.getImageData(canvas.width - 1, canvas.height - 1, 1, 1).data...
        @rgbToHex context.getImageData(0, canvas.height - 1, 1, 1).data...
      ]

    toHex: (c) ->
      hex = c.toString(16)
      hex = "0#{hex}" if hex.length is 1
      hex

    rgbToHex: (r, g, b) ->
      "##{@toHex(r)}#{@toHex(g)}#{@toHex(b)}"

    save: =>
      if @valid?
        if @valid then super else false
      else
        @load().then @save

    present: =>
      _.extend super, @validations, {@error, @valid}


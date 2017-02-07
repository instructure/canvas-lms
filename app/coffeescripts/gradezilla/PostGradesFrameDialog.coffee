define [
  'jquery'
  'jst/PostGradesFrameDialog'
  'jqueryui/dialog'
], ($, postGradesFrameDialog) ->

  class PostGradesFrameDialog
    constructor: (options) ->
      # init vars
      if options.returnFocusTo
        @returnFocusTo = options.returnFocusTo
      if options.baseUrl
        @baseUrl = options.baseUrl

      # init dialog
      @$dialog = $(postGradesFrameDialog())
      @$dialog.on('dialogopen', @onDialogOpen)
      @$dialog.on('dialogclose', @onDialogClose)
      @$dialog.dialog
        autoOpen: false
        resizable: false
        width: 800
        height: 600
        dialogClass: 'post-grades-frame-dialog'

      # other init
      if @baseUrl
        @$dialog.find(".post-grades-frame").attr('src', @baseUrl)

    open: =>
      @$dialog.dialog('open')

    close: =>
      @$dialog.dialog('close')

    onDialogOpen: (event) =>

    onDialogClose: (event) =>
      @$dialog.dialog('destroy').remove()
      if @returnFocusTo
        @returnFocusTo.focus()

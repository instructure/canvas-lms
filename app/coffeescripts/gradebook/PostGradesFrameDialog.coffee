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
        width: Number(options.launchWidth) || 800
        height: Number(options.launchHeight) || 600
        dialogClass: 'post-grades-frame-dialog'
        
      # listen for external tool events

      # other init
      if @baseUrl
        @$dialog.find(".post-grades-frame").attr('src', @baseUrl)

    open: =>
      @$dialog.dialog('open')

    close: =>
      @$dialog.dialog('close')

    onDialogOpen: (event) =>
      $(window).on('externalContentReady', @close)
      $(window).on('externalContentCancel', @close)

    onDialogClose: (event) =>
      $(window).off('externalContentReady', @close);
      $(window).off('externalContentCancel', @close);
      @$dialog.dialog('destroy').remove()
      if @returnFocusTo
        @returnFocusTo.focus()

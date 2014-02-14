define [
  'i18n!media_comments',
  'jquery',
  'jqueryui/dialog'
], (I18n, $) ->

  ###
  # manages uploader modal dialog
  ###
  class DialogManager

    initialize: ->
      @dialog = $("#media_comment_dialog")
      @createLoadingWindow()

    hide: =>
      $('#media_comment_dialog').dialog('close')

    createLoadingWindow: ->
      if @dialog.length == 0
        @dialog = $("<div/>").attr('id', 'media_comment_dialog')
      @dialog.text(I18n.t('messages.loading', "Loading..."))
      @dialog.dialog({
        title: I18n.t('titles.record_upload_media_comment', "Record/Upload Media Comment"),
        resizable: false,
        width: 470,
        height: 300,
        modal: true
      })
      @dialog = $('#media_comment_dialog')

    displayContent: (html) ->
      @dialog.html(html)

    mediaReady: (mediaType, opts) ->
      @showUpdateDialog()
      @setCloseOption(opts)
      @resetRecordHolders()
      @setupTypes(mediaType)

    showUpdateDialog: ->
      @dialog.dialog({
        title: I18n.t('titles.record_upload_media_comment', "Record/Upload Media Comment"),
        width: 560,
        height: 475,
        modal: true
      })

    setCloseOption: (opts) =>
      @dialog.dialog 'option', 'close', =>
        $("#audio_record").before("<div id='audio_record'/>").remove()
        $("#video_record").before("<div id='video_record'/>").remove()
        if(opts && opts.close && $.isFunction(opts.close))
          opts.close.call(@$dialog)

    setupTypes: (mediaType) ->
      if(mediaType == "video")
        $("#video_record_option").click()
        $("#media_record_option_holder").hide()
        $("#audio_upload_holder").hide()
        $("#video_upload_holder").show()
      else if(mediaType == "audio")
        $("#audio_record_option").click()
        $("#media_record_option_holder").hide()
        $("#audio_upload_holder").show()
        $("#video_upload_holder").hide()
      else
        $("#video_record_option").click()
        $("#audio_upload_holder").show()
        $("#video_upload_holder").show()

    resetRecordHolders: ->
      $("#audio_record").before("<div id='audio_record'/>").remove()
      $("#video_record").before("<div id='video_record'/>").remove()

    activateTabs: ->
      @dialog.find('#media_record_tabs').tabs()

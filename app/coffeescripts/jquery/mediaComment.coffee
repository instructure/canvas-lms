define [
  'i18n!media_comments'
  'underscore'
  'vendor/jquery.ba-tinypubsub'
  'vendor/mediaelement-and-player'
  'jquery'
], (I18n, _, pubsub, mejs, $) ->

  VIDEO_WIDTH = 550
  $.extend mejs.MediaElementDefaults,
    # shows debug errors on screen
    # enablePluginDebug: false
    # path to Flash and Silverlight plugins
    pluginPath: '/images/mediaelement/'
    # default if the <video width> is not specified
    defaultVideoWidth: VIDEO_WIDTH
    # default if the <video height> is not specified
    defaultVideoHeight: 448

  # track events in google analytics
  mejs.MepDefaults.features.push('googleanalytics')

  getSources = (id) ->
    dfd = new $.Deferred
    $.getJSON "/media_objects/#{id}/info", (data) ->
      sources = _.map data.media_sources, (source) -> "<source type='#{source.content_type}' src='#{source.url}' />"
      dfd.resolve {sources, can_add_captions: false}
    dfd

  mediaCommentActions =

    create: (mediaType, callback, onClose, defaultTitle) ->
      $("#media_recorder_container").removeAttr('id')
      this.attr('id', 'media_recorder_container')
      pubsub.unsubscribe 'media_comment_created'
      pubsub.subscribe 'media_comment_created', (data) =>
        callback.call undefined, data.id, data.mediaType

      initOpts = {modal: false, defaultTitle}
      initOpts.close = onClose.bind(this) if $.isFunction(onClose)

      $.mediaComment.init(mediaType, initOpts)


    show_inline: (id, mediaType = 'video', downloadUrl) ->
      $holder = $(this).closest('.instructure_file_link_holder').andSelf().first()
      $holder.text I18n.t('loading', 'Loading media...')

      showInline = (id) ->
        width = Math.min ($holder.closest("div,p,table").width() || VIDEO_WIDTH), VIDEO_WIDTH
        height = Math.round width / 336 * 240
        getSources(id).done (sources) ->
          if sources.sources.length
            $("#{if mediaType is 'video' then "<video width='#{width}' height='#{height}'" else '<audio'} controls preload autoplay />")
            .append(sources.sources.join(''))
              .appendTo($holder.html(''))
              .mediaelementplayer
                can_add_captions: false
                mediaCommendId: id
                googleAnalyticsTitle: id
          else
            $holder.text I18n.t('media_still_converting', 'Media is currently being converted, please try again in a little bit.')

      if id is 'maybe'
        detailsUrl = downloadUrl.replace /\/download.*/, ""
        onError = ->
          $holder.text I18n.t 'messages.file_failed_to_load', "This media file failed to load"
        onSuccess = (data) ->
          if data.attachment?.media_entry_id isnt 'maybe'
            $holder.text ''
            showInline data.attachment.media_entry_id
          else
            onError()
        $.ajaxJSON detailsUrl, 'GET', {}, onSuccess, onError
      else
        showInline(id)


    show: (id, mediaType) ->
      $this = $(this)
      if dialog = $this.data('media_comment_dialog')
        dialog.dialog('open')
      else
        spaceNeededForControls = 35
        mediaType = mediaType || 'video'
        height = if mediaType is'video' then 426 else 180
        width = if mediaType is 'video' then VIDEO_WIDTH else 400
        $dialog = $('<div style="overflow: hidden; padding: 0;" />')
        $dialog.css('padding-top', '120px') if mediaType is 'audio'
        $dialog.dialog
          title: I18n.t('titles.play_comment', "Play Media Comment")
          width: width
          height: height
          modal: false
          resizable: false
          close: -> $this.data('mediaelementplayer').pause()

        $dialog.disableWhileLoading getSources(id).done (sources) ->
          if sources.sources.length
            $mediaElement = $("#{if mediaType is 'video' then "<video width='#{width}' height='#{height - spaceNeededForControls}'" else '<audio'} controls preload autoplay />")
              .appendTo($dialog)

            $this.data
              mediaelementplayer: new MediaElementPlayer $mediaElement,
                can_add_captions: sources.can_add_captions
                mediaCommendId: id
                googleAnalyticsTitle: id
              media_comment_dialog: $dialog
          else
            $dialog.text I18n.t('media_still_converting', 'Media is currently being converted, please try again in a little bit.')

  $.fn.mediaComment = (command) ->
    return console.log('Kaltura has not been enabled for this account') unless INST.kalturaSettings
    mediaCommentActions[command].apply this, Array::slice.call(arguments, 1)
    this

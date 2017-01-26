#mediaComment.coffee
define [
  'i18n!media_comments'
  'underscore'
  'vendor/jquery.ba-tinypubsub'
  'vendor/mediaelement-and-player'
  'jquery'
  'compiled/util/kalturaAnalytics'
  'str/htmlEscape'
], (I18n, _, pubsub, mejs, $, kalturaAnalytics, htmlEscape) ->

  ##
  # a module for some of the transformation functions pulled out of the middle
  # of this jQuery plugin to keep their dependencies light
  #
  # @exports
  MediaCommentUtils = {
    ##
    # given the type and source/track tags, build
    # an html5 media element to replace our media comment when interacted
    # with
    #
    # @private
    #
    # @param {string} tagType should be "audio" or "video" generally, this is
    #   used for the name of the tag but also to decide whether to include
    #   width and height
    #
    # @param {HTML string} st_tags the html for the source and track tags that we
    #   might want to include inside the media element
    #
    # @param {int} width the desired width of the element, only applicable for
    #   video tags
    #
    # @param {int} height the desired height of the element, only applicable for
    #   video tags
    #
    # @returns {jQuery Object} a new dom element (not yet attached anywhere)
    #   that is the media element
    getElement: (tagType, st_tags, width, height) ->
      dimensions = ""
      if tagType is 'video'
        dimensions = " width='#{width}' height='#{height}'"
      html = "<#{tagType} #{dimensions} preload='metadata' controls>#{st_tags}</#{tagType}>"
      $(html)
  }

  VIDEO_WIDTH = 550
  VIDEO_HEIGHT = 448
  $.extend mejs.MediaElementDefaults,
    # shows debug errors on screen
    # enablePluginDebug: false
    # path to Flash and Silverlight plugins
    pluginPath: '/images/mediaelement/'
    # default if the <video width> is not specified
    defaultVideoWidth: VIDEO_WIDTH
    # default if the <video height> is not specified
    defaultVideoHeight: VIDEO_HEIGHT

  mejs.MepDefaults.success = (mediaElement, domObject) ->
    kalturaAnalytics(this.mediaCommentId, mediaElement, INST.kalturaSettings)
    mediaElement.play()

  # track events in google analytics
  mejs.MepDefaults.features.push('googleanalytics')

  positionAfterSubtitleSelector = mejs.MepDefaults.features.indexOf('tracks') + 1

  # enable the source chooser
  mejs.MepDefaults.features.splice(positionAfterSubtitleSelector, 0, 'sourcechooser')

  # enable the playback speed selector
  mejs.MepDefaults.features.splice(positionAfterSubtitleSelector, 0, 'speed')

  getSourcesAndTracks = (id) ->
    dfd = new $.Deferred
    $.getJSON "/media_objects/#{id}/info", (data) ->
      # this 'when ...' is because right now in canvas, none of the mp3 urls actually work.
      # see: CNVS-12998
      sources = for source in data.media_sources when source.content_type isnt 'audio/mp3'
        "<source type='#{htmlEscape source.content_type}' src='#{htmlEscape source.url}' title='#{htmlEscape source.width}x#{htmlEscape source.height} #{htmlEscape(Math.floor(source.bitrate / 1024))} kbps' />"

      tracks = _.map data.media_tracks, (track) ->
        languageName = mejs.language.codes[track.locale] || track.locale
        "<track kind='#{htmlEscape track.kind}' label='#{htmlEscape languageName}' src='#{htmlEscape track.url}' srclang='#{htmlEscape track.locale}' />"

      types = _.map data.media_sources, (source) -> source.content_type
      dfd.resolve {sources, tracks, types, can_add_captions: data.can_add_captions}
    dfd

  createMediaTag = ({sourcesAndTracks, mediaType, height, width, mediaPlayerOptions}) ->
    tagType = if mediaType is 'video' then 'video' else 'audio'
    st_tags = sourcesAndTracks.sources.concat(sourcesAndTracks.tracks).join('')
    willPlayAudioInFlash = ->
      opts = $.extend({mode: 'auto'}, mejs.MediaElementDefaults, mejs.MepDefaults,mediaPlayerOptions)
      element = MediaCommentUtils.getElement('audio', st_tags)
      playback = mejs.HtmlMediaElementShim.determinePlayback(element[0], opts, mejs.MediaFeatures.supportsMediaTag, !!'isMediaTag', null)
      return playback.method != 'native'

    # We only need to do this if we try to play audio in a flash player.
    # A lot of our recorded audio is actually served up via video/mp4 or video/flv.
    # We need to trick the flash player into playing the video, but looking like
    # an audio player.
    if mediaType is 'audio' and sourcesAndTracks.types[0].match(/^video\//) and willPlayAudioInFlash()
      tagType = 'video'
      mediaPlayerOptions.mode = 'auto_plugin'
      mediaPlayerOptions.isVideo = false
      mediaPlayerOptions.videoHeight = height = 30

    MediaCommentUtils.getElement(tagType, st_tags, width, height)

  mediaCommentActions =
    create: (mediaType, callback, onClose, defaultTitle) ->
      $("#media_recorder_container").removeAttr('id')
      this.attr('id', 'media_recorder_container')
      pubsub.unsubscribe 'media_comment_created'
      pubsub.subscribe 'media_comment_created', (data) =>
        callback(data.id, data.mediaType)

      initOpts = {modal: false, defaultTitle}
      initOpts.close = onClose.bind(this) if $.isFunction(onClose)

      $.mediaComment.init(mediaType, initOpts)

    show_inline: (id, mediaType = 'video', downloadUrl) ->
      # todo: replace .andSelf with .addBack when JQuery is upgraded.
      $holder = $(this).closest('.instructure_file_link_holder').andSelf().first()
      $holder.text I18n.t('loading', 'Loading media...')

      showInline = (id, holder) ->
        width = Math.min (holder.closest("div,p,table").width() || VIDEO_WIDTH), VIDEO_WIDTH
        height = Math.round width / 336 * 240
        getSourcesAndTracks(id).done (sourcesAndTracks) ->
          if sourcesAndTracks.sources.length
            mediaPlayerOptions =
              can_add_captions: sourcesAndTracks.can_add_captions
              mediaCommentId: id
              googleAnalyticsTitle: id
              success: (media)->
                holder.focus()
                media.play()

            $mediaTag = createMediaTag({sourcesAndTracks, mediaPlayerOptions, mediaType, height, width})
            $mediaTag.appendTo(holder.html(''))
            player = new MediaElementPlayer $mediaTag, mediaPlayerOptions
            $mediaTag.data('mediaelementplayer', player)
          else
            holder.text I18n.t('media_still_converting', 'Media is currently being converted, please try again in a little bit.')

      if id is 'maybe'
        detailsUrl = downloadUrl.replace /\/download.*/, ""
        onError = ->
          $holder.text I18n.t "Media has been queued for conversion, please try again in a little bit."
        onSuccess = (data) ->
          if data.attachment?.media_entry_id isnt 'maybe'
            $holder.text ''
            showInline(data.attachment.media_entry_id, $holder)
          else
            onError()
        $.ajaxJSON detailsUrl, 'GET', {}, onSuccess, onError
      else
        showInline(id, $holder)

    show: (id, mediaType) ->
      # if a media comment is still open, close it.
      $(".play_media_comment").find('.ui-dialog-titlebar-close').click()

      $this = $(this)

      if dialog = $this.data('media_comment_dialog')
        dialog.dialog('open')
      else
        # Create a dialog box
        mediaType = mediaType || 'video'

        if mediaType is 'video'
          height = 426
          width  = VIDEO_WIDTH
        else
          height = 180
          width  = 400

        $dialog = $('<div style="overflow: hidden; padding: 0;" />')
        $dialog.css('padding-top', '120px') if mediaType is 'audio'

        $dialog.dialog
          dialogClass: "play_media_comment"
          title: I18n.t('titles.play_comment', "Play Media Comment")
          width: width
          height: height + 60 # include height of dialog titlebar
          modal: false
          resizable: false
          close: ->
            $mediaPlayer = $this.data('mediaelementplayer')
            $mediaPlayer.pause() if $mediaPlayer
          open: (ev) -> $(ev.currentTarget).parent().
                          find('.ui-dialog-titlebar-close').
                          focus()

        # Populate dialog box with a video
        $dialog.disableWhileLoading getSourcesAndTracks(id).done (sourcesAndTracks) ->
          if sourcesAndTracks.sources.length
            mediaPlayerOptions =
              can_add_captions: sourcesAndTracks.can_add_captions
              mediaCommentId: id
              googleAnalyticsTitle: id

            $mediaTag = createMediaTag({sourcesAndTracks, mediaPlayerOptions, mediaType, height: height, width})
            $mediaTag.appendTo($dialog.html(''))

            $this.data
              mediaelementplayer: new MediaElementPlayer $mediaTag, mediaPlayerOptions
              media_comment_dialog: $dialog
          else
            $dialog.text I18n.t('media_still_converting', 'Media is currently being converted, please try again in a little bit.')

  $.fn.mediaComment = (command, restArgs...) ->
    return console.log('Kaltura has not been enabled for this account') unless INST.kalturaSettings
    mediaCommentActions[command].apply(this, restArgs)
    this

  MediaCommentUtils

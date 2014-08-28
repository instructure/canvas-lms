#mediaComment.coffee
define [
  'i18n!media_comments'
  'underscore'
  'vendor/jquery.ba-tinypubsub'
  'vendor/mediaelement-and-player'
  'jquery'
  'compiled/util/kalturaAnalytics'
], (I18n, _, pubsub, mejs, $, kalturaAnalytics) ->

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

  unless INST.enableHtml5FirstVideos
    # prefer flash player, as it works more consistently
    # for now, but allow fallback to html5 (like on mobile)
    mejs.MepDefaults.mode = 'auto_plugin'

  mejs.MepDefaults.success = (mediaElement, domObject) ->
    kalturaAnalytics(this.mediaCommentId, mediaElement, INST.kalturaSettings)
    mediaElement.play()

  # track events in google analytics
  mejs.MepDefaults.features.push('googleanalytics')

  # enable the playback speed selector
  positionAfterSubtitleSelector = mejs.MepDefaults.features.indexOf('tracks') + 1
  mejs.MepDefaults.features.splice(positionAfterSubtitleSelector, 0, 'speed')

  getSourcesAndTracks = (id) ->
    dfd = new $.Deferred
    $.getJSON "/media_objects/#{id}/info", (data) ->
      # this 'when ...' is because right now in canvas, none of the mp3 urls actually work.
      # see: CNVS-12998
      sources = for source in data.media_sources when source.content_type isnt 'audio/mp3'
        "<source type='#{source.content_type}' src='#{source.url}' />"

      tracks = _.map data.media_tracks, (track) ->
        languageName = mejs.language.codes[track.locale] || track.locale
        "<track kind='#{track.kind}' label='#{languageName}' src='#{track.url}' srclang='#{track.locale}' />"

      types = _.map data.media_sources, (source) -> source.content_type
      dfd.resolve {sources, tracks, types, can_add_captions: data.can_add_captions}
    dfd

  createMediaTag = ({sourcesAndTracks, mediaType, height, width, mediaPlayerOptions}) ->
    tagType = if mediaType is 'video' then 'video' else 'audio'
    st_tags = sourcesAndTracks.sources.concat(sourcesAndTracks.tracks).join('')

    getElement = (tagType) ->
      $("<#{tagType} #{if mediaType is 'video' then "width='#{width}' height='#{height}'" else ''} controls>#{st_tags}</#{tagType}>")

    willPlayAudioInFlash = ->
      opts = $.extend({mode: 'auto'}, mejs.MediaElementDefaults, mejs.MepDefaults,mediaPlayerOptions)
      playback = mejs.HtmlMediaElementShim.determinePlayback(getElement('audio')[0], opts, mejs.MediaFeatures.supportsMediaTag, !!'isMediaTag', null)
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

    getElement(tagType)

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

      showInline = (id) ->
        width = Math.min ($holder.closest("div,p,table").width() || VIDEO_WIDTH), VIDEO_WIDTH
        height = Math.round width / 336 * 240
        getSourcesAndTracks(id).done (sourcesAndTracks) ->
          if sourcesAndTracks.sources.length
            mediaPlayerOptions =
               can_add_captions: sourcesAndTracks.can_add_captions
               mediaCommentId: id
               googleAnalyticsTitle: id

            $mediaTag = createMediaTag({sourcesAndTracks, mediaPlayerOptions, mediaType, height, width})
            $mediaTag.appendTo($holder.html(''))
            player = new MediaElementPlayer $mediaTag, mediaPlayerOptions
            $mediaTag.data('mediaelementplayer', player)
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
        # Create a dialog box
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

        # Populate dialog box with a video
        $dialog.disableWhileLoading getSourcesAndTracks(id).done (sourcesAndTracks) ->
          if sourcesAndTracks.sources.length
            mediaPlayerOptions = 
              can_add_captions: sourcesAndTracks.can_add_captions
              mediaCommentId: id
              googleAnalyticsTitle: id

            $mediaTag = createMediaTag({sourcesAndTracks, mediaPlayerOptions, mediaType, height: height-spaceNeededForControls, width})
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

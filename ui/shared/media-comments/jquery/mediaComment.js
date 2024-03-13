//
// Copyright (C) 2011 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// mediaComment.js
import {useScope as useI18nScope} from '@canvas/i18n'
import * as pubsub from 'jquery-tinypubsub'
import mejs from '@canvas/mediaelement'
import MediaElementKeyActionHandler from './MediaElementKeyActionHandler'
import $ from 'jquery'
import {map, values} from 'lodash'
import htmlEscape from '@instructure/html-escape'
import sanitizeUrl from '@canvas/util/sanitizeUrl'
import {contentMapping} from '@instructure/canvas-rce/src/common/mimeClass'

const I18n = useI18nScope('jquery_media_comments')

// #
// a module for some of the transformation functions pulled out of the middle
// of this jQuery plugin to keep their dependencies light
//
// @exports
const MediaCommentUtils = {
  // #
  // given the type and source/track tags, build
  // an html5 media element to replace our media comment when interacted
  // with
  //
  // @private
  //
  // @param {string} tagType should be "audio" or "video" generally, this is
  //   used for the name of the tag but also to decide whether to include
  //   width and height
  //
  // @param {HTML string} st_tags the html for the source and track tags that we
  //   might want to include inside the media element
  //
  // @param {int} width the desired width of the element, only applicable for
  //   video tags
  //
  // @param {int} height the desired height of the element, only applicable for
  //   video tags
  //
  // @returns {jQuery Object} a new dom element (not yet attached anywhere)
  //   that is the media element
  getElement(tagType, st_tags, width, height) {
    const dimensions = tagType === 'video' ? ` width="${width}" height="${height}"` : ''
    const html = `<${tagType} ${dimensions} preload="metadata" controls>${st_tags}</${tagType}>`
    return $(html)
  },
}

const VIDEO_WIDTH = 550
const VIDEO_HEIGHT = 448
$.extend(mejs.MediaElementDefaults, {
  // shows debug errors on screen
  // enablePluginDebug: false
  // path to Flash and Silverlight plugins
  pluginPath: '/images/mediaelement/',
  // default if the <video width> is not specified
  defaultVideoWidth: VIDEO_WIDTH,
  // default if the <video height> is not specified
  defaultVideoHeight: VIDEO_HEIGHT,
})

mejs.MepDefaults.success = function (mediaElement, _domObject) {
  import('./kalturaAnalytics')
    .then(({default: kalturaAnalytics}) => {
      kalturaAnalytics(this.mediaCommentId, mediaElement, INST.kalturaSettings)
    })
    .catch(error => {
      console.log('Error importing kalturaAnalytics:', error) // eslint-disable-line no-console
    })
  return mediaElement.play()
}

const positionAfterSubtitleSelector = mejs.MepDefaults.features.indexOf('tracks') + 1

// enable the source chooser
mejs.MepDefaults.features.splice(positionAfterSubtitleSelector, 0, 'sourcechooser')

// enable the playback speed selector
mejs.MepDefaults.features.splice(positionAfterSubtitleSelector, 0, 'speed')

export function getSourcesAndTracks(id, attachmentId) {
  const dfd = new $.Deferred()
  const api = attachmentId ? 'media_attachments' : 'media_objects'
  $.getJSON(`/${api}/${attachmentId || id}/info`, data => {
    // this 'when ...' is because right now in canvas, none of the mp3 urls actually work.
    // see: CNVS-12998
    const sources = data.media_sources
      .filter(source => source.content_type !== 'audio/mp3')
      // mediaplayer plays the first source by default, which tends to be the highest
      // resolution. sort so we play the lowest res. by default
      .sort((a, b) => parseInt(a.bitrate, 10) - parseInt(b.bitrate, 10))
      .map(
        source =>
          // xsslint safeString.function sanitizeUrl
          `<source
            type='${htmlEscape(source.content_type)}'
            src='${sanitizeUrl(htmlEscape(source.url))}'
            title='${htmlEscape(source.width)}x${htmlEscape(source.height)} ${htmlEscape(
            Math.floor(source.bitrate / 1024)
          )} kbps'
          />`
      )

    const tracks = map(data.media_tracks, track => {
      const languageName = mejs.language.codes[track.locale] || track.locale
      return `<track kind='${htmlEscape(track.kind)}' label='${htmlEscape(
        languageName
      )}' src='${htmlEscape(track.url)}' srclang='${htmlEscape(track.locale)}'
      data-inherited-track='${htmlEscape(track.inherited)}' />`
    })

    const types = map(data.media_sources, source => source.content_type)
    return dfd.resolve({sources, tracks, types, can_add_captions: data.can_add_captions})
  })
  return dfd
}

function createMediaTag({sourcesAndTracks, mediaType, height, width, mediaPlayerOptions}) {
  let tagType = mediaType === 'video' ? 'video' : 'audio'
  const st_tags = sourcesAndTracks.sources.concat(sourcesAndTracks.tracks).join('')
  function willPlayAudioInFlash() {
    const opts = $.extend(
      {mode: 'auto'},
      mejs.MediaElementDefaults,
      mejs.MepDefaults,
      mediaPlayerOptions
    )
    const element = MediaCommentUtils.getElement('audio', st_tags)
    const playback = mejs.HtmlMediaElementShim.determinePlayback(
      element[0],
      opts,
      mejs.MediaFeatures.supportsMediaTag,
      !!'isMediaTag',
      null
    )
    return playback.method !== 'native'
  }

  // We only need to do this if we try to play audio in a flash player.
  // A lot of our recorded audio is actually served up via video/mp4 or video/flv.
  // We need to trick the flash player into playing the video, but looking like
  // an audio player.
  if (
    mediaType === 'audio' &&
    sourcesAndTracks.types[0].match(/^video\//) &&
    willPlayAudioInFlash()
  ) {
    tagType = 'video'
    mediaPlayerOptions.mode = 'auto_plugin'
    mediaPlayerOptions.isVideo = false
    mediaPlayerOptions.videoHeight = height = 30
  }

  return MediaCommentUtils.getElement(tagType, st_tags, width, height)
}

const mediaCommentActions = {
  create(mediaType, callback, onClose, defaultTitle) {
    $('#media_recorder_container').removeAttr('id')
    this.attr('id', 'media_recorder_container')
    pubsub.unsubscribe('media_comment_created')
    pubsub.subscribe('media_comment_created', data => callback(data.id, data.mediaType, data.title))

    const initOpts = {modal: false, defaultTitle}
    if ($.isFunction(onClose)) initOpts.close = onClose.bind(this)

    return $.mediaComment.init(mediaType, initOpts)
  },

  show_inline(
    id,
    mediaType = 'video',
    downloadUrl,
    attachmentId = null,
    lockedMediaAttachment = false
  ) {
    // todo: replace .andSelf with .addBack when JQuery is upgraded.
    const $holder = $(this).closest('.instructure_file_link_holder').andSelf().first()
    $holder.text(I18n.t('loading', 'Loading media...'))

    const showInline = function (mediaCommentId, holder) {
      const width = Math.min(holder.closest('div,p,table').width() || VIDEO_WIDTH, VIDEO_WIDTH)
      const height = Math.round((width / 336) * 240)
      return getSourcesAndTracks(mediaCommentId, attachmentId).done(sourcesAndTracks => {
        if (sourcesAndTracks.sources.length) {
          const mediaPlayerOptions = {
            can_add_captions: sourcesAndTracks.can_add_captions,
            mediaCommentId,
            attachmentId,
            lockedMediaAttachment,
            menuTimeoutMouseLeave: 50,
            success(media) {
              holder.focus()
              media.play()
            },
            keyActions: [
              {
                keys: values(MediaElementKeyActionHandler.keyCodes),
                action(player, media, keyCode, event) {
                  if (player.isVideo) {
                    player.showControls()
                    player.startControlsTimer()
                  }

                  const handler = new MediaElementKeyActionHandler(mejs, player, media, event)
                  handler.dispatch()
                },
              },
            ],
          }

          mediaType = contentMapping(mediaType)

          const $mediaTag = createMediaTag({
            sourcesAndTracks,
            mediaPlayerOptions,
            mediaType,
            height,
            width,
          })
          $mediaTag.appendTo(holder.html(''))
          const player = new mejs.MediaElementPlayer($mediaTag, mediaPlayerOptions)
          $mediaTag.data('mediaelementplayer', player)
        } else {
          holder.text(
            I18n.t(
              'media_still_converting',
              'Media is currently being converted, please try again in a little bit.'
            )
          )
        }
      })
    }

    if (id === 'maybe') {
      const detailsUrl = downloadUrl.replace(/\/download.*/, '')
      const onError = () =>
        $holder.text(
          I18n.t('Media has been queued for conversion, please try again in a little bit.')
        )
      const onSuccess = function (data) {
        if (data.attachment && data.attachment.media_entry_id !== 'maybe') {
          $holder.text('')
          return showInline(data.attachment.media_entry_id, $holder)
        } else {
          return onError()
        }
      }
      return $.ajaxJSON(detailsUrl, 'GET', {}, onSuccess, onError)
    } else {
      return showInline(id, $holder)
    }
  },

  show(id, mediaType = 'video', openingElement = null) {
    // if a media comment is still open, close it.
    $('.play_media_comment').find('.ui-dialog-titlebar-close').click()

    mediaType = contentMapping(mediaType)

    const $this = $(this)

    const dialog = $this.data('media_comment_dialog')
    if (dialog) {
      dialog.dialog('open')
    } else {
      // Create a dialog box
      let height, width
      if (mediaType === 'video') {
        height = 426
        width = VIDEO_WIDTH
      } else {
        height = 180
        width = 400
      }

      const $dialog = $('<div style="overflow: hidden; padding: 0;" />')
      if (mediaType === 'audio') $dialog.css('padding-top', '120px')

      $dialog.dialog({
        dialogClass: 'play_media_comment',
        title: I18n.t('titles.play_comment', 'Play Media Comment'),
        width,
        height: height + 60, // include height of dialog titlebar
        modal: false,
        resizable: false,
        close: () => {
          const $mediaPlayer = $this.data('mediaelementplayer')
          if ($mediaPlayer) $mediaPlayer.pause()

          if (openingElement) {
            openingElement.focus()
          }
        },
        open: event => {
          $(event.currentTarget)
            .closest('.ui-dialog')
            .attr('role', 'dialog')
            .attr('aria-label', I18n.t('Play Media Comment'))
          $(event.currentTarget).parent().find('.ui-dialog-titlebar-close').focus()
        },
        zIndex: 1000,
      })

      // Populate dialog box with a video
      return $dialog.disableWhileLoading(
        getSourcesAndTracks(id).done(sourcesAndTracks => {
          if (sourcesAndTracks.sources.length) {
            const mediaPlayerOptions = {
              can_add_captions: sourcesAndTracks.can_add_captions,
              mediaCommentId: id,
            }

            const $mediaTag = createMediaTag({
              sourcesAndTracks,
              mediaPlayerOptions,
              mediaType,
              height,
              width,
            })
            $mediaTag.appendTo($dialog.html(''))

            $this.data({
              mediaelementplayer: new mejs.MediaElementPlayer($mediaTag, mediaPlayerOptions),
              media_comment_dialog: $dialog,
            })
          } else {
            $dialog.text(
              I18n.t(
                'media_still_converting',
                'Media is currently being converted, please try again in a little bit.'
              )
            )
          }
        })
      )
    }
  },
}

$.fn.mediaComment = function (command, ...restArgs) {
  if (!INST.kalturaSettings) {
    return console.log('Kaltura has not been enabled for this account') // eslint-disable-line no-console
  } else {
    mediaCommentActions[command].apply(this, restArgs)
  }
  return this
}

export default MediaCommentUtils

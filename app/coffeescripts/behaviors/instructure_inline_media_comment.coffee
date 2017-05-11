#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!media_comments'
  'jquery'
  'compiled/fn/preventDefault'
  'str/htmlEscape'
  'compiled/jquery/mediaComment'
], (I18n, $, preventDefault, htmlEscape) ->

  inlineMediaComment = {
    buildMinimizerLink: ->
      $("<a href='#' style='font-size: 0.8em;'>
           #{htmlEscape I18n.t 'links.minimize_embedded_kaltura_content', 'Minimize embedded content'}
         </a>")

    buildCommentHolder: ($link)->
      $("<div><div tabindex='0' style='margin-bottom: 15px;'></div></div>")

    getMediaCommentId: ($link)->
      id = $link.data('media_comment_id') || $link.find(".media_comment_id:first").text()
      idAttr = $link.attr('id') if !id
      if idAttr && idAttr.match(/^media_comment_/)
        id = idAttr.substring(14)
      id

    collapseComment: ($holder)->
      $holder.find('video,audio').data('mediaelementplayer')?.pause()
      $holder.remove()
      $.trackEvent('hide_embedded_content', 'hide_media')
  }

  $(document).on 'click', 'a.instructure_inline_media_comment', preventDefault ->
    return alert(I18n.t('alerts.kaltura_disabled', "Kaltura has been disabled for this Canvas site")) unless INST.kalturaSettings

    $link = $(this)

    mediaType = 'video'
    id = inlineMediaComment.getMediaCommentId($link)
    $holder = inlineMediaComment.buildCommentHolder($link)
    $link.after($holder)
    $link.hide()

    mediaType = 'audio' if $link.data('media_comment_type') is 'audio' ||
                           $link.is('.audio_playback, .audio_comment, .instructure_audio_link')

    $holder.children("div").mediaComment('show_inline', id, mediaType, $link.data('download') || $link.attr('href'))

    $minimizer = inlineMediaComment.buildMinimizerLink()

    $minimizer.appendTo($holder).click preventDefault ->
      $link.show().focus()
      inlineMediaComment.collapseComment($holder)

    $.trackEvent('show_embedded_content', 'show_media')

  inlineMediaComment

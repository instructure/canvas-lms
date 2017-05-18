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
  'underscore'
  'str/htmlEscape'
  'jquery'
  'compiled/util/deparam'
], (I18n, _, htmlEscape, $, deparam) ->

  MEDIA_COMMENT_THUMBNAIL_SIZES =
    normal: {width: 140, height: 100}
    small: {width: 70, height: 50}

  createMediaCommentThumbnail = (elem, size, keepOriginalText) ->
    return console.log('Kaltura has not been enabled for this account') unless INST.kalturaSettings

    $link = $(elem)
    try
      a = document.createElement('a');
      a.href = $link.attr('href')
      url = a
    return if url && deparam(url.search).no_preview

    dimensions = MEDIA_COMMENT_THUMBNAIL_SIZES[size] ? MEDIA_COMMENT_THUMBNAIL_SIZES.normal
    id = $link.data('media_comment_id') ||
         $.trim($link.find(".media_comment_id:first").text()) ||
         ((idAttr = $link.attr('id')) && idAttr.match(/^media_comment_/) && idAttr.substring(14)) ||
         $.trim($link.parent().find(".media_comment_id:first").text())

    if id
      domain = "https://#{INST.kalturaSettings.resource_domain}"

      backgroundUrl = "#{domain}/p/#{INST.kalturaSettings.partner_id}/thumbnail/entry_id/#{id}/width/" +
                      "#{dimensions.width}/height/#{dimensions.height}/bgcolor/000000/type/2/vid_sec/5"

      $thumbnail = $ "<span
                        style='background-image: url(#{htmlEscape(backgroundUrl)});'
                        class='media_comment_thumbnail media_comment_thumbnail-#{htmlEscape(size)}'
                      >
                        <span class='media_comment_thumbnail_play_button'>
                          <span class='screenreader-only'>
                            #{htmlEscape I18n.t 'click_to_view', 'Click to view'}
                          </span>
                        </span>
                      </span>"

      $a = $link
      if keepOriginalText
        $a = $link.clone().empty().removeClass('instructure_file_link')
        $holder = $link.parent(".instructure_file_link_holder")
        if $holder.length
          $a.appendTo($holder)
        else
          $link.after($a)
      else
        $link.empty()

      $a
        .data('download', $a.attr('href'))
        .prop('href', '#')
        .addClass('instructure_inline_media_comment')
        .append($thumbnail)
        .css
          backgroundImage: ''
          padding: 0

  # public API
  $.fn.mediaCommentThumbnail = (size='normal', keepOriginalText) ->
    this.each ->
      # defer each thumbnail generation till the next time through the event loop to not kill browser rendering,
      # has the effect of saying "only work on thumbnailing these while the browser is not doing something else"
      _.defer(createMediaCommentThumbnail, this, size, keepOriginalText)

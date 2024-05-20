/* eslint-disable no-alert */
/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import 'jqueryui/dialog'
import {raw} from '@instructure/html-escape'

export default function (ed) {
  let $box = $('#equella_dialog')
  const url = $('#equella_endpoint_url').attr('href')
  const action = $.trim($('#equella_action').text() || '') || 'selectOrAdd'
  const callback_url = $('#equella_callback_url').attr('href')
  const cancel_url = $('#equella_cancel_url').attr('href')
  if (!url || !callback_url || !cancel_url) {
    alert(
      'Equella is not properly configured for this account, please notify your system administrator.'
    )
    return
  }
  const frameHeight = Math.max(Math.min($(window).height() - 100, 550), 100)
  if (!$box.length) {
    const boxHtml = '<div id="equella_dialog" style="padding: 0; overflow-y: hidden;"/>'
    const teaserAndIframeHtml =
      raw("<div class='teaser' style='width: 800px; margin-bottom: 10px; display: none;'></div>") +
      raw(
        "<iframe style='background: url(/images/ajax-loader-medium-444.gif) no-repeat left top; width: 800px; height: "
      ) +
      raw(frameHeight) +
      raw("px; border: 0;' src='about:blank' borderstyle='0'/>")
    $box = $(boxHtml)
      .hide()
      .html(teaserAndIframeHtml)
      .appendTo('body')
      .dialog({
        autoOpen: false,
        width: 'auto',
        resizable: true,
        resizeStart() {
          $(this)
            .find('iframe')
            .each(function () {
              $('<div class="fix_for_resizing_over_iframe" style="background: #fff;"></div>')
                .css({
                  width: this.offsetWidth + 'px',
                  height: this.offsetHeight + 'px',
                  position: 'absolute',
                  opacity: '0.001',
                  zIndex: 10000000,
                })
                .css($(this).offset())
                .appendTo('body')
            })
        },
        resizeStop() {
          $('.fix_for_resizing_over_iframe').remove()
        },
        resize() {
          $(this)
            .find('iframe')
            .add('.fix_for_resizing_over_iframe')
            .height($(this).height())
            .width($(this).width())
        },
        close() {
          $box.find('iframe').attr('src', 'about:blank')
        },
        title: 'Embed content from Equella',
        modal: true,
        zIndex: 1000,
      })
      .bind('equella_ready', (event, data) => {
        const selectedContent = ed.selection.getContent()
        if (selectedContent) {
          // selected content
          ed.execCommand('mceInsertLink', false, {
            title: data.name,
            href: data.url,
            class: 'equella_content_link',
          })
        } else {
          // no selected content
          const $link = $('<div><a/></div>')
          $link
            .find('a')
            .attr('title', data.name)
            .attr('href', data.url)
            .attr('class', 'equella_content_link')
            .text(data.name)
          ed.execCommand('mceInsertContent', false, $link.html())
        }
        $('#equella_dialog').dialog('close')
      })
  }
  const teaserHtml = $('#equella_teaser').html()
  $box.find('.teaser').hide()
  if (teaserHtml) {
    $box.find('.teaser').html(teaserHtml).show()
  }
  let full_url = url
  full_url = full_url + '?method=lms&returnprefix=eq_&action=' + action
  full_url = full_url + '&returnurl=' + encodeURIComponent(callback_url)
  full_url = full_url + '&cancelurl=' + encodeURIComponent(cancel_url)
  $box.data('editor', ed)
  $box.dialog('close').dialog('open')
  $box.find('iframe').attr('src', full_url)
}

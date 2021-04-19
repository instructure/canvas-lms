/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import htmlEscape from 'html-escape'
import {trackEvent} from '@canvas/google-analytics'
import '@canvas/module-sequence-footer'
import MarkAsDone from '@canvas/util/jquery/markAsDone'
import ToolLaunchResizer from '@canvas/lti/jquery/tool_launch_resizer'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'

const $toolForm = $('#tool_form')

const launchToolManually = function() {
  const $button = $toolForm.find('button')

  $toolForm.show()

  // Firefox remembers disabled state after page reloads
  $button.attr('disabled', false)
  setTimeout(() => {
    // LTI links have a time component in the signature and will
    // expire after a few minutes.
    $button.attr('disabled', true).text($button.data('expired_message'))
  }, 60 * 2.5 * 1000)

  $toolForm.submit(function() {
    $(this)
      .find('.load_tab,.tab_loaded')
      .toggle()
  })
}

const launchToolInNewTab = function() {
  $toolForm.attr('target', '_blank')
  launchToolManually()
}

switch ($toolForm.data('tool-launch-type')) {
  case 'window':
    $toolForm.show()
    launchToolInNewTab()
    break
  case 'self':
    $toolForm.removeAttr('target')
    try {
      $toolForm.submit()
    } catch (e) {}
    break
  default:
    // Firefox throws an error when submitting insecure content
    try {
      $toolForm.submit()
    } catch (e) {}

    $('#tool_content').bind('load', () => {
      if (
        document.location.protocol !== 'https:' ||
        $('#tool_form')[0].action.indexOf('https:') > -1
      ) {
        $('#insecure_content_msg').hide()
        $toolForm.hide()
      }
    })
    setTimeout(() => {
      if ($('#insecure_content_msg').is(':visible')) {
        $('#load_failure').show()
        launchToolInNewTab()
      }
    }, 3 * 1000)
    break
}

// Google analytics tracking code
const toolName = $toolForm.data('tool-id') || 'unknown'
const toolPath = $toolForm.data('tool-path')
const messageType = $toolForm.data('message-type') || 'tool_launch'
trackEvent(messageType, toolName, toolPath)

// Iframe resize handler
let $tool_content_wrapper
let min_tool_height, canvas_chrome_height

$(function() {
  const $window = $(window)
  $tool_content_wrapper = $('.tool_content_wrapper')
  const toolResizer = new ToolLaunchResizer(min_tool_height)
  const $tool_content = $('iframe#tool_content')

  const $external_content_info_alerts = $tool_content_wrapper.find(
    '.before_external_content_info_alert, .after_external_content_info_alert'
  )

  $external_content_info_alerts.on('focus', function(e) {
    $tool_content_wrapper.find('iframe').css('border', '2px solid #008EE2')
    $(this).removeClass('screenreader-only-tool')
  })

  $external_content_info_alerts.on('blur', function(e) {
    $tool_content_wrapper.find('iframe').css('border', 'none')
    $(this).addClass('screenreader-only-tool')
  })

  if (!$('body').hasClass('ic-full-screen-lti-tool')) {
    canvas_chrome_height = $tool_content_wrapper.offset().top + $('#footer').outerHeight(true)
  }

  // Only calculate height on resize if body does not have
  // .ic-full-screen-lti-tool class
  if ($tool_content_wrapper.length && !$('body').hasClass('ic-full-screen-lti-tool')) {
    $window
      .resize(() => {
        if (!$tool_content_wrapper.data('height_overridden')) {
          toolResizer.resize_tool_content_wrapper(
            $window.height() - canvas_chrome_height - $('#sequence_footer').outerHeight(true)
          )
        }
      })
      .triggerHandler('resize')
  }

  if (ENV.LTI != null && ENV.LTI.SEQUENCE != null) {
    $('#module_sequence_footer').moduleSequenceFooter({
      assetType: 'Lti',
      assetID: ENV.LTI.SEQUENCE.ASSET_ID,
      courseID: ENV.LTI.SEQUENCE.COURSE_ID
    })
  }

  $('#content').on('click', '#mark-as-done-checkbox', function() {
    MarkAsDone.toggle(this)
  })
})

monitorLtiMessages()

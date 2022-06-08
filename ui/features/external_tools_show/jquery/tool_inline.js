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
import {trackEvent} from '@canvas/google-analytics'
import '@canvas/module-sequence-footer'
import MarkAsDone from '@canvas/util/jquery/markAsDone'
import ToolLaunchResizer from '@canvas/lti/jquery/tool_launch_resizer'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'
import ready from '@instructure/ready'

ready(() => {
  const $toolForm = $('#tool_form')

  const launchToolManually = function () {
    const $button = $toolForm.find('button')

    $toolForm.show()

    // Firefox remembers disabled state after page reloads
    $button.attr('disabled', false)
    setTimeout(() => {
      // LTI links have a time component in the signature and will
      // expire after a few minutes.
      $button.attr('disabled', true).text($button.data('expired_message'))
    }, 60 * 2.5 * 1000)

    $toolForm.submit(function () {
      $(this).find('.load_tab,.tab_loaded').toggle()
    })
  }

  const launchToolInNewTab = function () {
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
        // eslint-disable-next-line no-empty
      } catch (e) {}
      break
    default:
      // Firefox throws an error when submitting insecure content
      try {
        $toolForm.submit()
        // eslint-disable-next-line no-empty
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
  const $tool_content_wrapper = $('.tool_content_wrapper')
  let tool_height, canvas_chrome_height

  const $window = $(window)
  const toolResizer = new ToolLaunchResizer(tool_height)

  const $external_content_info_alerts = $tool_content_wrapper.find(
    '.before_external_content_info_alert, .after_external_content_info_alert'
  )

  $external_content_info_alerts.on('focus', function () {
    $tool_content_wrapper.find('iframe').css('border', '2px solid #0374B5')
    $(this).removeClass('screenreader-only-tool')
  })

  $external_content_info_alerts.on('blur', function () {
    $tool_content_wrapper.find('iframe').css('border', 'none')
    $(this).addClass('screenreader-only-tool')
  })

  const is_full_screen = $('body').hasClass('ic-full-screen-lti-tool')

  if (!is_full_screen) {
    canvas_chrome_height = $tool_content_wrapper.offset().top + $('#footer').outerHeight(true)
  }

  if ($tool_content_wrapper.length) {
    $window
      .on('resize', () => {
        // https://api.jquery.com/resize/
        // https://developer.mozilla.org/en-US/docs/Web/API/Window/resize_event

        if (!$tool_content_wrapper.data('height_overridden')) {
          if (is_full_screen) {
            // divs from app/views/lti/_lti_message.html.erb that usually have 1px
            const div_before_iframe =
              document.querySelector('div.before_external_content_info_alert')?.offsetHeight || 0
            const div_after_iframe =
              document.querySelector('div.after_external_content_info_alert')?.offsetHeight || 0

            // header#mobile-header
            //   hidden when screen width > 768px
            //   see app/stylesheets/base/_ic_app_header.scss
            //   see https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/offsetHeight
            const mobile_header_height =
              document.querySelector('header#mobile-header')?.offsetHeight || 0

            tool_height =
              window.innerHeight - mobile_header_height - div_before_iframe - div_after_iframe

            toolResizer.resize_tool_content_wrapper(tool_height, $tool_content_wrapper, true)
          } else {
            toolResizer.resize_tool_content_wrapper(
              $window.height() -
                canvas_chrome_height -
                // module item navigation from PLAT-1687
                $('#sequence_footer').outerHeight(true)
            )
          }
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

  $('#content').on('click', '#mark-as-done-checkbox', function () {
    MarkAsDone.toggle(this)
  })
})

monitorLtiMessages()

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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit */
import 'jqueryui/progressbar'

const I18n = useI18nScope('content_exports')

$(document).ready(function (_event) {
  let state = 'nothing'
  let current_id = null
  const $quiz_selection = $('#quiz_selection'),
    $exporter_form = $('#exporter_form')

  function startPoll() {
    $exporter_form
      .html(
        htmlEscape(I18n.t('messages.processing', 'Processing')) +
          "<div style='font-size: 0.8em;'>" +
          htmlEscape(I18n.t('messages.this_may_take_a_bit', 'this may take a bit...')) +
          '</div>'
      )
      .prop('disabled', true)
    $('.instruction').hide()
    $('.progress_bar_holder').slideDown()
    $('.export_progress').progressbar()
    state = 'nothing'
    let fakeTickCount = 0
    const tick = function () {
      if (state === 'nothing') {
        fakeTickCount++
        const progress = ($('.export_progress').progressbar('option', 'value') || 0) + 0.25
        if (fakeTickCount < 10) {
          $('.export_progress').progressbar('option', 'value', progress)
        }
        setTimeout(tick, 2000)
      } else {
        state = 'nothing'
        fakeTickCount = 0
        setTimeout(tick, 10000)
      }
    }
    const checkup = function () {
      let lastProgress = null
      let waitTime = 1500
      $.ajaxJSON(
        window.location.href + '/' + current_id,
        'GET',
        {},
        data => {
          state = 'updating'
          const content_export = data.content_export
          let progress = 0
          if (content_export) {
            progress = Math.max(
              $('.export_progress').progressbar('option', 'value') || 0,
              content_export.progress
            )
            $('.export_progress').progressbar('option', 'value', progress)
          }
          if (content_export.workflow_state === 'exported') {
            $exporter_form.hide()
            $('.export_progress').progressbar('option', 'value', 100)
            $('.progress_message').text(I18n.t('Your content has been exported.'))
            $('#export_files').append(
              '<p><a href="' +
                htmlEscape(content_export.download_url) +
                '">' +
                htmlEscape(I18n.t('New Export')) +
                '</a></p>'
            )
          } else if (content_export.workflow_state === 'failed') {
            const code = 'content_export_' + content_export.id
            $('.progress_bar_holder').hide()
            $exporter_form.hide()
            const message = I18n.t(
              'errors.error',
              'There was an error exporting your content.  Please notify your system administrator and give them the following export identifier: "%{code}"',
              {code}
            )
            $('.export_messages .error_message').text(message)
            $('.export_messages').show()
          } else {
            if (progress == lastProgress) {
              waitTime = Math.max(waitTime + 500, 30000)
            } else {
              waitTime = 1500
            }
            lastProgress = progress
            setTimeout(checkup, 1500)
          }
        },
        () => {
          setTimeout(checkup, 3000)
        }
      )
    }
    setTimeout(checkup, 2000)
    setTimeout(tick, 1000)
  }

  $exporter_form.formSubmit({
    success(data) {
      if (data && data.content_export) {
        current_id = data.content_export.id
        startPoll()
      } else {
        // show error message
        $('.export_messages .error_message').text(data.error_message)
        $('.export_messages').show()
      }
    },
    error(_data) {
      $(this)
        .find('.submit_button')
        .prop('disabled', false)
        .text(I18n.t('buttons.process', 'Process Data'))
    },
  })

  $exporter_form.on('click', '.copy_all', function () {
    $('.quiz_item').prop('checked', $(this).prop('checked'))
  })

  $exporter_form.on('click', '.quiz_item', function () {
    if (!$(this).prop('checked')) {
      $('.copy_all').prop('checked', false)
    }
  })

  $exporter_form.on('click', 'input[name=export_type]', function () {
    if ($(this).val() === 'qti') {
      $quiz_selection.show()
    } else {
      $quiz_selection.hide()
    }
  })

  function check_if_exporting() {
    // state = "checking";
    if ($('#current_export_id').size()) {
      // state = "nothing";
      current_id = $('#current_export_id').text()
      startPoll()
    }
  }
  check_if_exporting()
})

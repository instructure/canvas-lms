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
import htmlEscape, {raw} from '@instructure/html-escape'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, formErrors */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf, disableIf */
import 'jqueryui/progressbar'

const I18n = useI18nScope('sis_import')

$(document).ready(function (_event) {
  let state = 'nothing'

  $('#batch_mode')
    .change(function (__event) {
      $('#batch_mode_term_id_label').showIf($(this).prop('checked'))
      $('#batch_mode_term_id').showIf($(this).prop('checked'))
    })
    .change()

  const $override_sis_stickiness = $('#override_sis_stickiness')
  const $add_sis_stickiness = $('#add_sis_stickiness')
  const $clear_sis_stickiness = $('#clear_sis_stickiness')
  const $add_sis_stickiness_container = $('#add_sis_stickiness_container')
  const $clear_sis_stickiness_container = $('#clear_sis_stickiness_container')
  function updateSisCheckboxes(__event) {
    $add_sis_stickiness_container.showIf($override_sis_stickiness.prop('checked'))
    $clear_sis_stickiness_container.showIf($override_sis_stickiness.prop('checked'))
    $add_sis_stickiness.disableIf($clear_sis_stickiness.prop('checked'))
    $clear_sis_stickiness.disableIf($add_sis_stickiness.prop('checked'))
  }

  $override_sis_stickiness.change(updateSisCheckboxes)
  $add_sis_stickiness.change(updateSisCheckboxes)
  $clear_sis_stickiness.change(updateSisCheckboxes)
  updateSisCheckboxes(null)

  function createMessageHtml(batch) {
    let output = ''
    if (batch.processing_errors && batch.processing_errors.length > 0) {
      output +=
        '<li>' +
        htmlEscape(I18n.t('headers.import_errors', 'Errors that prevent importing')) +
        '\n<ul>'
      for (const i in batch.processing_errors) {
        const message = batch.processing_errors[i]
        output += '<li>' + htmlEscape(message[0]) + ' - ' + htmlEscape(message[1]) + '</li>'
      }
      output += '</ul>\n</li>'
    }
    if (batch.processing_warnings && batch.processing_warnings.length > 0) {
      output += '<li>' + htmlEscape(I18n.t('headers.import_warnings', 'Warnings')) + '\n<ul>'
      for (const i in batch.processing_warnings) {
        const message = batch.processing_warnings[i]
        output += '<li>' + htmlEscape(message[0]) + ' - ' + htmlEscape(message[1]) + '</li>'
      }
      output += '</ul>\n</li>'
    }
    output += '</ul>'
    return output
  }

  function createCountsHtml(batch) {
    if (!(batch.data && batch.data.counts)) {
      return ''
    }
    let output =
      '<ul><li>' + htmlEscape(I18n.t('headers.imported_items', 'Imported Items')) + '<ul>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.accounts', 'Accounts: %{account_count}', {
          account_count: batch.data.counts.accounts,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.terms', 'Terms: %{term_count}', {term_count: batch.data.counts.terms})
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.courses', 'Courses: %{course_count}', {
          course_count: batch.data.counts.courses,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.sections', 'Sections: %{section_count}', {
          section_count: batch.data.counts.sections,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.users', 'Users: %{user_count}', {user_count: batch.data.counts.users})
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.logins', 'Logins: %{login_count}', {
          login_count: batch.data.counts.logins,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.enrollments', 'Enrollments: %{enrollment_count}', {
          enrollment_count: batch.data.counts.enrollments,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.crosslists', 'Crosslists: %{crosslist_count}', {
          crosslist_count: batch.data.counts.xlists,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.admins', 'Admins: %{admin_count}', {
          admin_count: batch.data.counts.admins,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.group_categories', 'Group Categories: %{group_categories_count}', {
          group_categories_count: batch.data.counts.group_categories,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.groups', 'Groups: %{group_count}', {
          group_count: batch.data.counts.groups,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.group_enrollments', 'Group Enrollments: %{group_enrollments_count}', {
          group_enrollments_count: batch.data.counts.group_memberships,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.user_observers', 'User Observers: %{user_observers_count}', {
          user_observers_count: batch.data.counts.user_observers,
        })
      ) +
      '</li>'
    output +=
      '<li>' +
      htmlEscape(
        I18n.t('import_counts.change_sis_ids', 'Change SIS IDs: %{change_sis_ids_count}', {
          change_sis_ids_count: batch.data.counts.change_sis_ids,
        })
      ) +
      '</li>'
    output += '</ul></li></ul>'

    return output
  }

  function startPoll() {
    $('#sis_importer')
      .html(
        htmlEscape(I18n.t('status.processing', 'Processing')) +
          " <div style='font-size: 0.6em;'>" +
          htmlEscape(I18n.t('notices.processing_takes_awhile', 'this may take a bit...')) +
          '</div>'
      )
      .prop('disabled', true)
    $('.instruction').hide()
    $('.progress_bar_holder').slideDown()
    $('.copy_progress').progressbar()
    state = 'nothing'
    let fakeTickCount = 0
    const tick = function () {
      if (state === 'nothing') {
        fakeTickCount++
        const progress = ($('.copy_progress').progressbar('option', 'value') || 0) + 0.25
        if (fakeTickCount < 10) {
          $('.copy_progress').progressbar('option', 'value', progress)
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
        window.location.href,
        'GET',
        {},
        data => {
          state = 'updating'
          const sis_batch = data
          let progress = 0
          if (sis_batch) {
            progress = Math.max(
              $('.copy_progress').progressbar('option', 'value') || 0,
              sis_batch.progress
            )
            $('.copy_progress').progressbar('option', 'value', progress)
            $('#import_log').empty()
          }
          if (!sis_batch || sis_batch.workflow_state === 'imported') {
            $('#sis_importer').hide()
            $('.copy_progress').progressbar('option', 'value', 100)
            $('.progress_message').html(
              raw(
                htmlEscape(
                  I18n.t(
                    'messages.import_complete_success',
                    'The import is complete and all records were successfully imported.'
                  )
                ) + createCountsHtml(sis_batch)
              )
            )
          } else if (sis_batch.workflow_state === 'failed') {
            const code = 'sis_batch_' + sis_batch.id
            $('.progress_bar_holder').hide()
            $('#sis_importer').hide()
            {
              const message = I18n.t(
                'errors.import_failed_code',
                'There was an error importing your SIS data. Please notify your system administrator and give them the following code: "%{code}"',
                {code}
              )
              $('.sis_messages .sis_error_message').text(message)
            }
            $('.sis_messages').show()
          } else if (sis_batch.workflow_state === 'failed_with_messages') {
            $('.progress_bar_holder').hide()
            $('#sis_importer').hide()
            {
              let message = htmlEscape(
                I18n.t('errors.import_failed_messages', 'The import failed with these messages:')
              )
              message += createMessageHtml(sis_batch)
              $('.sis_messages .sis_error_message').html(raw(message))
            }
            $('.sis_messages').show()
          } else if (sis_batch.workflow_state === 'imported_with_messages') {
            $('.progress_bar_holder').hide()
            $('#sis_importer').hide()
            {
              let message = htmlEscape(
                I18n.t(
                  'messages.import_complete_warnings',
                  'The SIS data was imported but with these messages:'
                )
              )
              message += createMessageHtml(sis_batch)
              message += createCountsHtml(sis_batch)
              $('.sis_messages').show().html(raw(message))
            }
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

  $('#sis_importer').formSubmit({
    fileUpload: true,
    success(data) {
      if (data && data.id) {
        startPoll()
      } else {
        // show error message
        $('.sis_messages .sis_error_message').text(data.error_message)
        $('.sis_messages').show()
        if (data.batch_in_progress) {
          startPoll()
        }
      }
    },
    error(data) {
      $(this)
        .find('.submit_button')
        .prop('disabled', false)
        .text(I18n.t('buttons.process_data', 'Process Data'))
      $(this).formErrors(data)
    },
  })

  function check_if_importing() {
    state = 'checking'
    $.ajaxJSON(window.location.href, 'GET', {}, data => {
      state = 'nothing'
      const sis_batch = data
      if (
        sis_batch &&
        (sis_batch.workflow_state === 'importing' || sis_batch.workflow_state === 'created')
      ) {
        state = 'nothing'
        startPoll()
      }
    })
  }
  check_if_importing()
})

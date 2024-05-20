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
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf */
import '@canvas/util/templateData'

const I18n = useI18nScope('link_enrollment')
/* fillTemplateData */

/* global link_enrollment */
window.link_enrollment = (function () {
  return {
    choose(user_name, enrollment_id, current_user_id, callback) {
      const $dialog = $('#link_student_dialog')
      const user_data = {}
      user_data.short_name = user_name
      $dialog.fillTemplateData({data: user_data})
      $dialog.data('callback', callback)
      if (!$dialog.data('loaded')) {
        $dialog
          .find('.loading_message')
          .text(I18n.t('messages.loading_students', 'Loading Students...'))
        $dialog.find('.student_options option:not(.blank)').remove()
        const url = $dialog.find('.student_url').attr('href')
        $.ajaxJSON(
          url,
          'GET',
          {},
          data => {
            for (const idx in data) {
              const user = data[idx]
              const $option = $('<option/>')
              if (user.id && user.name) {
                $option.val(user.id).text(user.name)
                $dialog.find('.student_options').append($option)
              }
            }
            const $option = $('<option/>')
            $option.val('none').text(I18n.t('options.no_link', '[ No Link ]'))
            $dialog.find('.student_options').append($option)

            $dialog.find('.loading_message').hide().end().find('.students_link').show()

            link_enrollment.updateDialog($dialog, enrollment_id, current_user_id)

            $dialog.data('loaded', true)
          },
          () => {
            $dialog
              .find('.loading_message')
              .text(I18n.t('errors.load_failed', 'Loading Students Failed, please try again'))
          }
        )
      } else {
        link_enrollment.updateDialog($dialog, enrollment_id, current_user_id)
      }
      $dialog.find('.existing_user').showIf(current_user_id)

      $dialog.dialog({
        title: I18n.t('titles.link_to_student', 'Link to Student'),
        width: 400,
        modal: true,
        zIndex: 1000,
      })
    },
    updateDialog($dialog, enrollment_id, current_user_id) {
      $dialog.find('.enrollment_id').val(enrollment_id)
      $dialog.find('.existing_user').showIf(current_user_id)
      $dialog.find('.student_options').val('none').val(current_user_id)

      const user_data = {}
      user_data.existing_user_name = $dialog
        .find(".student_options option[value='" + current_user_id + "']")
        .first()
        .text()
      $dialog.fillTemplateData({data: user_data})
    },
  }
})()
$(document).ready(function () {
  $(document).bind('enrollment_added', () => {
    $('#link_student_dialog').data('loaded', false)
  })
  $('#link_student_dialog .cancel_button').click(() => {
    $('#link_student_dialog').dialog('close')
  })
  $('#link_student_dialog_form').formSubmit({
    beforeSubmit(_data) {
      $(this)
        .find('button')
        .prop('disabled', true)
        .end()
        .find('.save_button')
        .text(I18n.t('messages.linking_to_student', 'Linking to Student...'))
    },
    success(data) {
      $(this)
        .find('button')
        .prop('disabled', false)
        .end()
        .find('.save_button')
        .text(I18n.t('buttons.link', 'Link to Student'))
      const enrollment = data.enrollment
      const callback = $('#link_student_dialog').data('callback')
      $('#link_student_dialog').dialog('close')
      if ($.isFunction(callback) && enrollment) {
        callback(enrollment)
      }
    },
    error(_data) {
      $(this)
        .find('button')
        .prop('disabled', false)
        .find('.save_button')
        .text(I18n.t('errors.link_failed', 'Linking Failed, please try again'))
    },
  })
})

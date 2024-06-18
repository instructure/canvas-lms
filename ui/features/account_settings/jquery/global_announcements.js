/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import RichContentEditor from '@canvas/rce/RichContentEditor'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/jquery/jquery.instructure_misc_plugins'

const I18n = useI18nScope('account_settings')

// optimization so user isn't waiting on RCS to
// respond when they hit announcements
RichContentEditor.preloadRemoteModule()

// account_settings.js mixes a lot of dom management for each of it's
// tabs, so this file is meant to encapsulate just the javascript
// used for working with the Announcements tab
export default {
  bindDomEvents() {
    $('.add_notification_toggle_focus').on('click', function () {
      const form_id = '#add_notification_form'
      const visibility = $(form_id).css('display')

      if (visibility === 'block') {
        $(form_id).css('display', 'none')
      } else {
        const title_el = $(form_id).find('#account_notification_subject')
        const message_el = $(form_id).find('#account_notification_message')

        title_el.val('')
        $(form_id).find('#account_notification_icon').val('information')
        message_el.val('')
        $(form_id).find('#domain_specific').prop('checked', false)

        const roles = $(form_id).find('[id^=account_notification_role_]')
        for (let i = 0; i < roles.length; i++) {
          const field_id = '#' + roles[i].id
          $(form_id).find(field_id).prop('checked', false)
        }

        $(form_id).find('#account_notification_start_at').val('')
        $(form_id)
          .find('#account_notification_start_at')
          .parent()
          .find('input[name="account_notification[start_at]"]')
          .val('')
        $(form_id).find('#account_notification_end_at').val('')
        $(form_id)
          .find('#account_notification_end_at')
          .parent()
          .find('input[name="account_notification[end_at]"]')
          .val('')
        $(form_id).find('#account_notification_send_message').prop('checked', false)

        $(form_id).css('display', 'block')

        setTimeout(() => {
          title_el.focus()
        }, 100)

        RichContentEditor.loadNewEditor(message_el)
      }
    })

    $('.copy_notification_toggle_focus').on('click', function () {
      const announcement_id = $(this).attr('data-copy-toggle-id')
      const source_form_id = '#edit_notification_form_' + announcement_id
      const target_form_id = '#add_notification_form'
      const target_form_visibility = $(target_form_id).css('display')

      if (target_form_visibility === 'block') {
        $(target_form_id).css('display', 'none')
      }

      const target_title_el = $(target_form_id).find('#account_notification_subject')
      const target_message_el = $(target_form_id).find('#account_notification_message')

      const title = $(source_form_id)
        .find('#account_notification_subject_' + announcement_id)
        .val()
      target_title_el.val(title)

      const announcement_type = $(source_form_id)
        .find('#account_notification_icon_' + announcement_id)
        .val()
      $(target_form_id).find('#account_notification_icon').val(announcement_type)

      const message = $(source_form_id)
        .find('#account_notification_message_' + announcement_id)
        .val()
      target_message_el.val(message)

      const domain_specific = $(source_form_id)
        .find('#domain_specific_' + announcement_id)
        .is(':checked')
      $(target_form_id).find('#domain_specific').prop('checked', domain_specific)

      const source_roles = $(source_form_id).find('[id^=account_notification_role_]')
      for (let i = 0; i < source_roles.length; i++) {
        const source_id = '#' + source_roles[i].id
        const source_value = source_roles[i].checked
        const target_id = source_id.substring(0, source_id.indexOf('cbx') + 3)
        $(target_form_id).find(target_id).prop('checked', source_value)
      }

      const source_start_at_disp_el = $(source_form_id).find(
        '#account_notification_start_at_' + announcement_id
      )
      const target_start_at_disp_el = $(target_form_id).find('#account_notification_start_at')
      const target_start_at_value_el = target_start_at_disp_el
        .parent()
        .find('input[name="account_notification[start_at]"]')
      target_start_at_disp_el.val(source_start_at_disp_el.val())
      if (source_start_at_disp_el.is('[readonly]')) {
        target_start_at_value_el.val(source_start_at_disp_el.attr('data-initial-value'))
      } else {
        const source_start_at_value_el = source_start_at_disp_el
          .parent()
          .find('input[name="account_notification[start_at]"]')
        target_start_at_value_el.val(source_start_at_value_el.val())
      }

      const source_end_at_disp_el = $(source_form_id).find(
        '#account_notification_end_at_' + announcement_id
      )
      const target_end_at_disp_el = $(target_form_id).find('#account_notification_end_at')
      const target_end_at_value_el = target_end_at_disp_el
        .parent()
        .find('input[name="account_notification[end_at]"]')
      target_end_at_disp_el.val(source_end_at_disp_el.val())
      if (source_end_at_disp_el.is('[readonly]')) {
        target_end_at_value_el.val(source_end_at_disp_el.attr('data-initial-value'))
      } else {
        const source_end_at_value_el = source_end_at_disp_el
          .parent()
          .find('input[name="account_notification[end_at]"]')
        target_end_at_value_el.val(source_end_at_value_el.val())
      }

      const send_message = $(source_form_id)
        .find('#account_notification_send_message_' + announcement_id)
        .is(':checked')
      $(target_form_id).find('#account_notification_send_message').prop('checked', send_message)

      $(target_form_id).css('display', 'block')

      setTimeout(() => {
        target_title_el.focus()
      }, 100)

      RichContentEditor.loadNewEditor(target_message_el)
    })

    $('.edit_notification_toggle_focus').on('click', function () {
      const id = $(this).attr('data-edit-toggle-id')
      const form_id = '#edit_notification_form_' + id
      const aria_expanded = $(form_id).attr('aria-expanded') === 'true'
      if (!aria_expanded) {
        setTimeout(() => {
          $('#account_notification_subject_' + id).focus()
        }, 100)
      }
      RichContentEditor.loadNewEditor($(`${form_id} textarea`))
    })

    $('.add_notification_cancel_focus').on('click', () => {
      $('#add_announcement_button').focus()
    })

    $('.edit_cancel_focus').on('click', function () {
      const id = $(this).attr('data-cancel-focus-id')
      $('#notification_edit_' + id).focus()
    })

    $('#add_notification_form, .edit_notification_form').on('submit', function () {
      const $this = $(this)
      const $confirmation = $this.find('#confirm_global_announcement:visible:not(:checked)')
      if ($confirmation.length > 0) {
        $confirmation.errorBox(
          I18n.t('confirms.global_announcement', 'You must confirm the global announcement')
        )
        return false
      }
      const validations = {
        object_name: 'account_notification',
        required: ['start_at', 'end_at', 'subject', 'message'],
        date_fields: ['start_at', 'end_at'],
        numbers: [],
        property_validations: {
          subject(value) {
            if (value && value.length > 255) {
              return I18n.t('Title is too long')
            }
          },
        },
      }
      if (
        $this[0].id === 'add_notification_form' &&
        $('#account_notification_months_in_display_cycle').length > 0
      ) {
        validations.numbers.push('months_in_display_cycle')
      }
      const result = $this.validateForm(validations)
      if (!result) {
        return false
      }
    })

    $('#account_notification_required_account_service').on('click', function () {
      const $this = $(this)
      $('#confirm_global_announcement_field').showIf(!$this.is(':checked'))
      $('#account_notification_months_in_display_cycle').prop('disabled', !$this.is(':checked'))
    })

    $('.delete_notification_link').on('click', function (event) {
      event.preventDefault()
      const $link = $(this)
      $link.parents('li').confirmDelete({
        url: $link.attr('data-url'),
        message: I18n.t(
          'confirms.delete_announcement',
          'Are you sure you want to delete this announcement?'
        ),
        success() {
          $(this).slideUp(function () {
            $(this).remove()
          })
        },
      })
    })
  },
}

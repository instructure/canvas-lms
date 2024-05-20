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
    $('.add_notification_toggle_focus').on('click', () => {
      const aria_expanded = $('#add_notification_form').attr('aria-expanded') === 'true'
      if (!aria_expanded) {
        setTimeout(() => {
          $('#account_notification_subject').focus()
        }, 100)
      }
      RichContentEditor.loadNewEditor($(`#add_notification_form textarea`))
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

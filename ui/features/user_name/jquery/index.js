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

import I18n from 'i18n!user_name'
import $ from 'jquery'
import htmlEscape from 'html-escape'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/forms/jquery/jquery.instructure_forms' /* formSubmit */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData'

import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'

$(document).ready(function() {
  $('#name_and_email').delegate('.edit_user_link', 'click', event => {
    event.preventDefault()
    $('#edit_student_dialog').dialog({
      width: 450
    })
    $('#edit_student_form :text:visible:first')
      .focus()
      .select()
  })
  $('#edit_student_form').formSubmit({
    beforeSubmit(_data) {
      $(this)
        .find('button')
        .attr('disabled', true)
        .filter('.submit_button')
        .text(I18n.t('messages.updating_user_details', 'Updating User Details...'))
    },
    success(data) {
      $(this)
        .find('button')
        .attr('disabled', false)
        .filter('.submit_button')
        .text(I18n.t('buttons.update_user', 'Update User'))
      $('#name_and_email .user_details').fillTemplateData({data})
      $('#edit_student_dialog').dialog('close')
    },
    error(_data) {
      $(this)
        .find('button')
        .attr('disabled', false)
        .filter('.submit_button')
        .text(
          I18n.t(
            'errors.updating_user_details_failed',
            'Updating user details failed, please try again'
          )
        )
    }
  })
  $('#edit_student_dialog .cancel_button').click(() => {
    $('#edit_student_dialog').dialog('close')
  })
  $('.remove_avatar_picture_link').click(async function(event) {
    event.preventDefault()
    const $link = $(this)
    const result = await showConfirmationDialog({
      label: I18n.t('Confirm Removal'),
      body: I18n.t(
        'confirms.remove_profile_picture',
        "Are you sure you want to remove this user's profile picture?"
      )
    })
    if (!result) {
      return
    }
    $link.text(I18n.t('messages.removing_image', 'Removing image...'))
    $.ajaxJSON(
      $link.attr('href'),
      'PUT',
      {'avatar[state]': 'none'},
      _data => {
        $link
          .parents('tr')
          .find('.avatar_image')
          .remove()
        $link.remove()
      },
      _data => {
        $link.text(
          I18n.t('errors.failed_to_remove_image', 'Failed to remove the image, please try again')
        )
      }
    )
  })
  $('.report_avatar_picture_link').click(function(event) {
    event.preventDefault()
    event.preventDefault()
    const $link = $(this)
    $link.text(I18n.t('messages.reporting_image', 'Reporting image...'))
    $.ajaxJSON(
      $link.attr('href'),
      'POST',
      {},
      _data => {
        $link.after(htmlEscape(I18n.t('notices.image_reported', 'This image has been reported')))
        $link.remove()
      },
      _data => {
        $link.text(
          I18n.t('errors.failed_to_report_image', 'Failed to report the image, please try again')
        )
      }
    )
  })
  $('.clear_user_cache_link').click(function(event) {
    event.preventDefault()
    const $link = $(this)
    $.ajaxJSON(
      $link.attr('href'),
      'POST',
      {},
      _data => {
        $.flashMessage(I18n.t('Cache cleared successfully'))
      },
      _data => {
        $.flashMessage(I18n.t('Failed to clear cache'))
      }
    )
  })
  $('.destroy_user_link').click(async function(event) {
    event.preventDefault()
    const result = await showConfirmationDialog({
      label: I18n.t('Confirm Deletion'),
      body: I18n.t('Are you sure you want to permanently remove the user from ALL accounts')
    })
    if (!result) {
      return
    }
    const $link = $(this)
    $.ajaxJSON(
      $link.attr('href'),
      'DELETE',
      {},
      _data => {
        $.flashMessage(I18n.t('User removed successfully'))
      },
      _data => {
        $.flashMessage(I18n.t('Failed to remove user'))
      }
    )
  })
})

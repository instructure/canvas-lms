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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {createRoot} from 'react-dom/client'
import Pseudonym from '@canvas/pseudonyms/backbone/models/Pseudonym'
import AvatarWidget from '@canvas/avatar-dialog-view'
import '@canvas/jquery/jquery.ajaxJSON'
import {datetimeString} from '@canvas/datetime/date-functions'
import {renderDatetimeField} from '@canvas/datetime/jquery/DatetimeField'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, formErrors, errorBox */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */
import '@canvas/loading-image'
import '@canvas/util/templateData'
import 'jqueryui/sortable'
import '@canvas/rails-flash-notifications'
import AccessTokenDetails from '../react/AccessTokenDetails'
import NewAccessToken from '../react/NewAccessToken'
import RegisterService from '../react/RegisterService'

const I18n = createI18nScope('profile')

const $edit_settings_link = $('.edit_settings_link')

const $profile_table = $('.profile_table'),
  $update_profile_form = $('#update_profile_form'),
  $default_email_id = $('#default_email_id')

const localizeWorkflowState = function (state) {
  switch (state) {
    case 'active':
      return I18n.t('active')
    case 'pending':
      return I18n.t('pending')
    default:
      return state
  }
}

$edit_settings_link.click(function () {
  $(this).hide()
  $profile_table
    .addClass('editing')
    .find('.edit_data_row')
    .show()
    .end()
    .find(':focusable:first')
    .focus()
    .select()
  return false
})

$profile_table.find('.cancel_button').click(() => {
  $edit_settings_link.show()
  $profile_table
    .removeClass('editing')
    .find('.change_password_row,.edit_data_row,.more_options_row')
    .hide()
    .end()
    .find('#change_password_checkbox')
    .prop('checked', false)
  return false
})

$profile_table
  .find('#change_password_checkbox')
  .change(function () {
    if (!$(this).prop('checked')) {
      $profile_table.find('.change_password_row').hide().find(':password').val('')
    } else {
      $(this).addClass('showing')
      $profile_table.find('.change_password_row').show().find('#old_password').focus().select()
    }
  })
  .prop('checked', false)
  .change()

$update_profile_form
  .attr('method', 'PUT')
  .formSubmit({
    formErrors: false,
    required: $update_profile_form.find('#user_name').length ? ['name'] : [],
    object_name: 'user',
    property_validations: {
      '=default_email_id': function (val, _data) {
        if ($('#default_email_id').length && (!val || val === 'new')) {
          return I18n.t('please_select_an_option', 'Please select an option')
        }
      },
    },
    beforeSubmit() {},
    success(data) {
      const user = data.user
      const templateData = {
        short_name: user.short_name,
        full_name: user.name,
        sortable_name: user.sortable_name,
        time_zone: user.time_zone,
        locale: $("#user_locale option[value='" + user.locale + "']").text(),
      }
      if (templateData.locale != $update_profile_form.find('.locale').text()) {
        window.location.reload()
        return
      }
      if ($default_email_id.length > 0) {
        const default_email = $default_email_id.find('option:selected').text()
        $('.default_email.display_data').text(default_email)
      }
      $('.channel').removeClass('default')
      $('#channel_' + user.communication_channel.id).addClass('default')
      $update_profile_form
        .fillTemplateData({
          data: templateData,
        })
        .find('.cancel_button')
        .click()
    },
    error(errors) {
      if (errors.password) {
        const pseudonymId = $(this).find('#profile_pseudonym_id').val()
        errors = Pseudonym.prototype.normalizeErrors(
          errors,
          ENV.PASSWORD_POLICIES[pseudonymId] || ENV.PASSWORD_POLICY,
        )
      }
      $update_profile_form.loadingImage('remove').formErrors(errors)
      $edit_settings_link.click()
    },
  })
  .find('.more_options_link')
  .click(() => {
    $update_profile_form.find('.more_options_link_row').hide()
    $update_profile_form.find('.more_options_row').show()
    return false
  })

$('#default_email_id').change(function () {
  if ($(this).val() === 'new') {
    $('.add_email_link:first').click()
  }
})

$('#unregistered_services li.service').click(function (event) {
  event.preventDefault()

  const mountPoint = document.getElementById('register_service_mount_point')
  const root = createRoot(mountPoint)
  const serviceName = $(this).attr('id').replace('unregistered_service_', '')

  root.render(
    <RegisterService
      serviceName={serviceName}
      onSubmit={() => {
        root.unmount()

        document.location.reload()
      }}
      onClose={() => root.unmount()}
    />,
  )
})
$('#registered_services li.service .delete_service_link').click(function (event) {
  event.preventDefault()
  $(this)
    .parents('li.service')
    .confirmDelete({
      message: I18n.t(
        'confirms.unregister_service',
        'Are you sure you want to unregister this service?',
      ),
      url: $(this).attr('href'),
      success() {
        $(this).slideUp(function () {
          $('#unregistered_services')
            .find('#unregistered_' + $(this).attr('id'))
            .slideDown()
        })
      },
    })
})
$('.service').hover(
  function () {
    $(this).addClass('service-hover')
  },
  function () {
    $(this).removeClass('service-hover')
  },
)
$('#show_user_services').change(function () {
  $.ajaxJSON(
    $('#update_profile_form').attr('action'),
    'PUT',
    {'user[show_user_services]': $(this).prop('checked')},
    _data => {},
    _data => {},
  )
})
$('#disable_inbox').change(function () {
  $.ajaxJSON(
    '/profile/toggle_disable_inbox',
    'POST',
    {'user[disable_inbox]': $(this).prop('checked')},
    _data => {},
    _data => {},
  )
})
$('.delete_pseudonym_link').click(function (event) {
  event.preventDefault()
  $(this)
    .parents('.pseudonym')
    .confirmDelete({
      url: $(this).attr('href'),
      message: I18n.t('confirms.delete_login', 'Are you sure you want to delete this login?'),
    })
})
renderDatetimeField($('.datetime_field'))
$('.expires_field').bind('change keyup', function () {
  $(this).closest('td').find('.hint').showIf(!$(this).val())
})
$('.delete_key_link').click(function (event) {
  event.preventDefault()
  const $key_row = $(this).closest('.access_token')
  let $focus_row = $key_row.prevAll(':not(.blank)').first()
  if ($focus_row.length === 0) {
    $focus_row = $key_row.nextAll(':not(.blank)').first()
  }
  const $to_focus =
    $focus_row.length > 0 ? $('.delete_key_link', $focus_row) : $('.add_access_token_link')
  $key_row.confirmDelete({
    url: $(this).attr('rel'),
    message: I18n.t(
      'confirms.delete_access_key',
      'Are you sure you want to delete this access key?',
    ),
    success() {
      $(this).remove()
      if (!$('.access_token:visible').length) {
        $('#no_approved_integrations,#access_tokens_holder').toggle()
      }
      $to_focus.focus()
    },
  })
})
$('.access_token .activate_token_link').click(function () {
  const $button = $(this)
  const url = $button.attr('rel')
  $button.text(I18n.t('buttons.activating_token', 'activating...')).prop('disabled', true)
  $.ajaxJSON(
    url,
    'POST',
    {},
    data => {
      $button.parentElement.replaceChildren(localizeWorkflowState(data.workflow_state))
    },
    () => {
      $button
        .text(I18n.t('errors.activating_token_failed', 'Activating Token Failed'))
        .prop('disabled', false)
    },
  )
})
$('.show_token_link').click(function (event) {
  event.preventDefault()

  const url = $(this).attr('rel')
  const tokenElement = $(this).parents('.access_token')
  const token = tokenElement.data('token')
  const userCanUpdateTokens = ENV.PERMISSIONS.can_update_tokens ?? false
  const mountPoint = document.getElementById('access_token_details_mount_point')
  const root = createRoot(mountPoint)

  root.render(
    <AccessTokenDetails
      url={url}
      loadedToken={token}
      userCanUpdateTokens={userCanUpdateTokens}
      onTokenLoad={loadedToken => {
        const data = {
          ...loadedToken,
          created: datetimeString(loadedToken.created_at) || '--',
          expires: datetimeString(loadedToken.expires_at) || I18n.t('token_never_expires', 'never'),
          used: datetimeString(loadedToken.last_used_at) || '--',
          visible_token: loadedToken.visible_token || 'protected',
          workflow_state: localizeWorkflowState(loadedToken.workflow_state),
        }
        tokenElement.data('token', data)
      }}
      onClose={() => root.unmount()}
    />,
  )
})

$('.add_access_token_link').click(function (event) {
  event.preventDefault()

  const mountPoint = document.getElementById('new_access_token_mount_point')
  const root = createRoot(mountPoint)

  root.render(
    <NewAccessToken
      onSubmit={data => {
        root.unmount()

        $('#no_approved_integrations').hide()
        $('#access_tokens_holder').show()

        const $token = $('.access_token.blank:first').clone(true).removeClass('blank')
        data.created = datetimeString(data.created_at) || '--'
        data.expires = datetimeString(data.expires_at) || I18n.t('token_never_expires', 'never')
        data.used = '--'
        data.workflow_state = localizeWorkflowState(data.workflow_state)

        $token.fillTemplateData({
          data,
          hrefValues: ['id'],
        })
        $token.data('token', data)
        $('#access_tokens > tbody').append($token.show())
        $token.find('.show_token_link').click()
      }}
      onClose={() => root.unmount()}
    />,
  )
})
$(document)
  .fragmentChange((event, hash) => {
    let type = hash.substring(1)
    if (type.match(/^register/)) {
      type = type.substring(9)
    }
    if ($('#unregistered_service_' + type + ':visible').length > 0) {
      $('#unregistered_service_' + type + ':visible').click()
    }
  })
  .fragmentChange()

new AvatarWidget('.profile_pic_link')

$('#disable_mfa_link').click(function (event) {
  const $disable_mfa_link = $(this)
  $.ajaxJSON($disable_mfa_link.attr('href'), 'DELETE', {}, () => {
    $.flashMessage(I18n.t('notices.mfa_disabled', 'Multi-factor authentication disabled'))
    $disable_mfa_link.remove()
    $('#otp_backup_codes_link').remove()
  })
  event.preventDefault()
})

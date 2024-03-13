/* eslint-disable eqeqeq, no-alert */
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
import Pseudonym from '@canvas/pseudonyms/backbone/models/Pseudonym'
import AvatarWidget from '@canvas/avatar-dialog-view'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime/jquery' /* datetimeString, time_field, datetime_field */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, formErrors, errorBox */
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */
import '@canvas/loading-image'
import '@canvas/util/templateData'
import 'jqueryui/sortable'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('profile')

const $edit_settings_link = $('.edit_settings_link')

const $profile_table = $('.profile_table'),
  $update_profile_form = $('#update_profile_form'),
  $default_email_id = $('#default_email_id')

const maximumStringLength = 255

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
          ENV.PASSWORD_POLICIES[pseudonymId] || ENV.PASSWORD_POLICY
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
  $('#' + $(this).attr('id') + '_dialog').dialog({
    width: 350,
    open() {
      $(this).dialog('widget').find('a').focus()
    },
  })
})
$('.create_user_service_form').formSubmit({
  object_name: 'user_service',
  property_validations: {
    user_name(value) {
      if (value && value.length > maximumStringLength) {
        return I18n.t('Exceeded the maximum length (%{number} characters)', {
          number: maximumStringLength,
        })
      }
    },
  },
  beforeSubmit() {
    $(this).loadingImage()
  },
  success() {
    $(this).loadingImage('remove').parents('.content').dialog('close')
    document.location.reload()
  },
  error() {
    $(this)
      .loadingImage('remove')
      .errorBox(
        I18n.t(
          'errors.registration_failed',
          'Registration failed. Check the user name and password, and try again.'
        )
      )
  },
})
$('#unregistered_services li.service .content form .cancel_button').click(function () {
  $(this).parents('.content').dialog('close')
})
$('#registered_services li.service .delete_service_link').click(function (event) {
  event.preventDefault()
  $(this)
    .parents('li.service')
    .confirmDelete({
      message: I18n.t(
        'confirms.unregister_service',
        'Are you sure you want to unregister this service?'
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
  }
)
$('#show_user_services').change(function () {
  $.ajaxJSON(
    $('#update_profile_form').attr('action'),
    'PUT',
    {'user[show_user_services]': $(this).prop('checked')},
    _data => {},
    _data => {}
  )
})
$('#disable_inbox').change(function () {
  $.ajaxJSON(
    '/profile/toggle_disable_inbox',
    'POST',
    {'user[disable_inbox]': $(this).prop('checked')},
    _data => {},
    _data => {}
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
$('.datetime_field').datetime_field()
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
      'Are you sure you want to delete this access key?'
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
$('#add_access_token_dialog .cancel_button').click(() => {
  $('#add_access_token_dialog').dialog('close')
})
$('#access_token_form').formSubmit({
  object_name: 'access_token',
  property_validations: {
    purpose(value) {
      if (!value || value === '') {
        return I18n.t('purpose_required', 'Purpose is required')
      }
      if (value.length > maximumStringLength) {
        return I18n.t('Exceeded the maximum length (%{number} characters)', {
          number: maximumStringLength,
        })
      }
    },
  },
  beforeSubmit() {
    $(this)
      .find('button')
      .prop('disabled', true)
      .filter('.submit_button')
      .text(I18n.t('buttons.generating_token', 'Generating Token...'))
  },
  success(data) {
    $(this)
      .find('button')
      .prop('disabled', false)
      .filter('.submit_button')
      .text(I18n.t('buttons.generate_token', 'Generate Token'))
    $('#add_access_token_dialog').dialog('close')
    $('#no_approved_integrations').hide()
    $('#access_tokens_holder').show()
    const $token = $('.access_token.blank:first').clone(true).removeClass('blank')
    data.created = $.datetimeString(data.created_at) || '--'
    data.expires =
      $.datetimeString(data.permanent_expires_at) || I18n.t('token_never_expires', 'never')
    data.used = '--'
    $token.fillTemplateData({
      data,
      hrefValues: ['id'],
    })
    $token.data('token', data)
    $('#access_tokens > tbody').append($token.show())
    $token.find('.show_token_link').click()
  },
  error() {
    $(this)
      .find('button')
      .prop('disabled', false)
      .filter('.submit_button')
      .text(I18n.t('errors.generating_token_failed', 'Generating Token Failed'))
  },
})
$('#token_details_dialog .regenerate_token').click(function () {
  const result = window.confirm(
    I18n.t(
      'confirms.regenerate_token',
      'Are you sure you want to regenerate this token?  Anything using this token will have to be updated.'
    )
  )
  if (!result) {
    return
  }

  const $dialog = $('#token_details_dialog')
  const $token = $dialog.data('token')
  const url = $dialog.data('token_url')
  const $button = $(this)
  $button.text(I18n.t('buttons.regenerating_token', 'Regenerating token...')).prop('disabled', true)
  $.ajaxJSON(
    url,
    'PUT',
    {'access_token[regenerate]': '1'},
    data => {
      data.created = $.datetimeString(data.created_at) || '--'
      data.expires =
        $.datetimeString(data.permanent_expires_at) || I18n.t('token_never_expires', 'never')
      data.used = $.datetimeString(data.last_used_at) || '--'
      data.visible_token = data.visible_token || 'protected'
      $dialog
        .fillTemplateData({data})
        .find('.full_token_warning')
        .showIf(data.visible_token.length > 10)
      $token.data('token', data)
      $button.text(I18n.t('buttons.regenerate_token', 'Regenerate Token')).prop('disabled', false)
    },
    () => {
      $button
        .text(I18n.t('errors.regenerating_token_failed', 'Regenerating Token Failed'))
        .prop('disabled', false)
    }
  )
})
$('.show_token_link').click(function (event) {
  event.preventDefault()
  const $dialog = $('#token_details_dialog')
  const url = $(this).attr('rel')
  $dialog.dialog({
    width: 700,
    modal: true,
    zIndex: 1000,
  })
  const $token = $(this).parents('.access_token')
  $dialog.data('token', $token)
  $dialog.find('.loading_message').show().end().find('.results,.error_loading_message').hide()
  function tokenLoaded(token) {
    $dialog.fillTemplateData({data: token})
    $dialog.data('token_url', url)
    $dialog
      .find('.refresh_token')
      .showIf(token.visible_token && token.visible_token !== 'protected')
      .find('.regenerate_token')
      .text(I18n.t('buttons.regenerate_token', 'Regenerate Token'))
      .prop('disabled', false)
    $dialog
      .find('.loading_message,.error_loading_message')
      .hide()
      .end()
      .find('.results')
      .show()
      .end()
      .find('.full_token_warning')
      .showIf(token.visible_token.length > 10)
    $dialog.find('.regenerate_token').focus()
  }
  const token = $token.data('token')
  if (token) {
    tokenLoaded(token)
  } else {
    $.ajaxJSON(
      url,
      'GET',
      {},
      data => {
        data.created = $.datetimeString(data.created_at) || '--'
        data.expires =
          $.datetimeString(data.permanent_expires_at) || I18n.t('token_never_expires', 'never')
        data.used = $.datetimeString(data.last_used_at) || '--'
        data.visible_token = data.visible_token || 'protected'
        $token.data('token', data)
        tokenLoaded(data)
      },
      () => {
        $dialog.find('.error_loading_message').show().end().find('.results,.loading_message').hide()
      }
    )
  }
})
$('.add_access_token_link').click(function (event) {
  event.preventDefault()
  $('#access_token_form')
    .find('button')
    .prop('disabled', false)
    .filter('.submit_button')
    .text(I18n.t('buttons.generate_token', 'Generate Token'))
  $('#add_access_token_dialog')
    .find(':input')
    .val('')
    .end()
    .dialog({
      width: 500,
      open() {
        $(this).closest('.ui-dialog').focus()
      },
      modal: true,
      zIndex: 1000,
    })
    .fixDialogButtons()
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

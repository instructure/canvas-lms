/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import ready from '@instructure/ready'
import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from '@instructure/html-escape'
import {loadSignupDialog} from '@canvas/signup-dialog'
import 'jquery-fancy-placeholder' /* fancyPlaceholder */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, getFormData, formErrors, errorBox */
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('pseudonyms.login')

$('#coenrollment_link').click(function (event) {
  event.preventDefault()
  const template = $(this).data('template')
  const path = $(this).data('path')
  loadSignupDialog
    .then(signupDialog => {
      signupDialog(template, I18n.t('parent_signup', 'Parent Signup'), path)
    })
    .catch(error => {
      throw new Error('Failed to load signup dialog', error)
    })
})

$('.field-with-fancyplaceholder input').fancyPlaceholder()
$('#forgot_password_form').formSubmit({
  object_name: 'pseudonym_session',
  required: ['unique_id_forgot'],
  beforeSubmit(_data) {
    $(this).loadingImage()
  },
  success(_data) {
    $(this).loadingImage('remove')
    $.flashMessage(
      htmlEscape(
        I18n.t(
          'Your password recovery instructions will be sent to *%{email_address}*. This may take up to 30 minutes. Make sure to check your spam box.',
          {
            wrappers: ['<b>$1</b>'],
            email_address: $(this).find('.email_address').val(),
          }
        )
      ),
      15 * 60 * 1000 // fifteen minutes isn't forever but should be plenty
    )
    // Focus on the close button of the alert we just put up, per a11y
    $('#flash_message_holder button.close_link').focus()
  },
  error(_data) {
    $(this).loadingImage('remove')
  },
})

$('#login_form').submit(function (_event) {
  const data = $(this).getFormData<
    Partial<{
      unique_id: string
      password: string
    }>
  >({object_name: 'pseudonym_session'})
  let success = true
  if (!data.unique_id || data.unique_id.length < 1) {
    $(this).formErrors({
      unique_id: I18n.t('invalid_login', 'Invalid login'),
    })
    success = false
  } else if (!data.password || data.password.length < 1) {
    $(this).formErrors({
      password: I18n.t('invalid_password', 'Invalid password'),
    })
    success = false
  }

  if (success) {
    // disable the button to avoid double-submit
    const $btn = $(this).find('input[type="submit"]')
    $btn.val($btn.data('disable-with'))
    $btn.prop('disabled', true)
  }

  return success
})

ready(() => {
  const $loginForm = $('#login_form')
  const $forgotPasswordForm = $('#forgot_password_form')

  $('.forgot_password_link').click(event => {
    event.preventDefault()
    $loginForm.hide()
    $forgotPasswordForm.show()
    $forgotPasswordForm.find('input:visible:first').focus()
  })

  $('.login_link').click(event => {
    event.preventDefault()
    $forgotPasswordForm.hide()
    $loginForm.show()
    $loginForm.find('input:visible:first').focus()
  })

  // do not clear session storage if previewing via the theme editor
  if (!document.querySelector('.ic-Login--previewing')) {
    sessionStorage.clear()
  }
})

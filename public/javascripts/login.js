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

import I18n from 'i18n!pseudonyms.login'
import $ from 'jquery'
import htmlEscape from './str/htmlEscape'
import signupDialog from 'compiled/registration/signupDialog'
import './jquery.fancyplaceholder' /* fancyPlaceholder */
import './jquery.instructure_forms' /* formSubmit, getFormData, formErrors, errorBox */
import './jquery.loadingImg'
import 'compiled/jquery.rails_flash_notifications'

$('#coenrollment_link').click(function(event) {
  event.preventDefault()
  const template = $(this).data('template')
  const path = $(this).data('path')
  signupDialog(template, I18n.t('parent_signup', 'Parent Signup'), path)
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
            email_address: $(this)
              .find('.email_address')
              .val()
          }
        )
      ),
      15 * 60 * 1000 // fifteen minutes isn't forever but should be plenty
    )
    $('.login_link:first').click()
  },
  error(_data) {
    $(this).loadingImage('remove')
  }
})

$('#login_form').submit(function(_event) {
  const data = $(this).getFormData({object_name: 'pseudonym_session'})
  let success = true
  if (!data.unique_id || data.unique_id.length < 1) {
    $(this).formErrors({
      unique_id: I18n.t('invalid_login', 'Invalid login')
    })
    success = false
  } else if (!data.password || data.password.length < 1) {
    $(this).formErrors({
      password: I18n.t('invalid_password', 'Invalid password')
    })
    success = false
  }
  return success
})

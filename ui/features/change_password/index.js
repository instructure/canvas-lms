/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import registrationErrors from '@canvas/normalize-registration-errors'
import '@canvas/jquery/jquery.instructure_forms'

const $form = $('#change_password_form')
$form.formSubmit({
  disableWhileLoading: 'spin_on_success',
  errorFormatter(errors) {
    const pseudonymId = $form.find('#pseudonym_id_select').val()
    return registrationErrors(
      errors,
      ENV.PASSWORD_POLICIES[pseudonymId] != null
        ? ENV.PASSWORD_POLICIES[pseudonymId]
        : ENV.PASSWORD_POLICY
    )
  },
  success() {
    window.location.href = '/login/canvas?password_changed=1'
  },
  error(errors) {
    if (errors.nonce) window.location.href = '/login/canvas'
  },
})

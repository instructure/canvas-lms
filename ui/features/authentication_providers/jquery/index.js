/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import '@canvas/jquery/jquery.instructure_misc_helpers'

const authenticationProviders = {
  hideAllNewAuthTypeForms() {
    const newForms = document.querySelectorAll('.auth-form-container--new')
    Array.prototype.forEach.call(newForms, (el, _id) => {
      el.style.display = 'none'
    })
  },

  showFormFor(authType) {
    const formId = authType + '_form'
    const form = document.getElementById(formId)
    if (form !== null) {
      form.style.display = ''
      setTimeout(() => {
        $(form).find(':focusable:first').focus()
        form.scrollIntoView()
      }, 100)
    }
  },

  hideNoAuthMessage() {
    const noAuthMessage = document.getElementById('no_auth')
    if (noAuthMessage !== null) {
      noAuthMessage.style.display = 'none'
    }
  },

  changedAuthType(authType) {
    authenticationProviders.hideNoAuthMessage()
    authenticationProviders.hideAllNewAuthTypeForms()
    authenticationProviders.showFormFor(authType)
  },
}

export default authenticationProviders

//
// Copyright (C) 2023 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import CourseRestore from './CourseRestore'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/forms/jquery/jquery.instructure_forms'

const I18n = useI18nScope('user_restore')

export default class UserRestore extends CourseRestore {
  searchUrl() {
    return `/accounts/${this.get('account_id')}/users/${this.get('id')}.json`
  }

  // @api public
  restore = () => {
    this.trigger('restoring')
    const deferred = $.Deferred()

    let restoreError
    let restoreSuccess

    const ajaxRequest = (url, method = 'GET') =>
      $.ajax({
        url,
        type: method,
        success: restoreSuccess,
        error: restoreError,
      })

    restoreError = (_response = {}) => {
      $.flashError(
        I18n.t('There was an error attempting to restore the user. User was not restored.')
      )
      return deferred.reject()
    }

    restoreSuccess = response => {
      this.set({login_id: response.login_id, restored: true})
      this.trigger('doneRestoring')
      return deferred.resolve()
    }

    ajaxRequest(`/api/v1/accounts/${this.get('account_id')}/users/${this.get('id')}/restore`, 'PUT')
    return deferred
  }
}

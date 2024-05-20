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
import ready from '@instructure/ready'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.instructure_forms'

const I18n = useI18nScope('terms_of_use')

ready(() => {
  $('form.reaccept_terms').submit(function () {
    const checked = !!$('input[name="user[terms_of_use]"]').is(':checked')
    if (!checked) {
      $(this).formErrors({'user[terms_of_use]': I18n.t('You must agree to the terms')})
    }
    return checked
  })
})

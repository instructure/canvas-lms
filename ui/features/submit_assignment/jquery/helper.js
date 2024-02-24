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
import '@canvas/jquery/jquery.instructure_misc_plugins'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('submit_assignment_helper')

export function recordEulaAgreement(querySelector, checked) {
  const inputs = document.querySelectorAll(querySelector)
  for (let i = 0; i < inputs.length; ++i) {
    inputs[i].value = checked ? new Date().getTime() : ''
  }
}

export function verifyPledgeIsChecked(checkbox) {
  if (checkbox.length > 0 && !checkbox.prop('checked')) {
    alert(
      I18n.t(
        'messages.agree_to_pledge',
        'You must agree to the submission pledge before you can submit this assignment.'
      )
    )
    return false
  }
  return true
}

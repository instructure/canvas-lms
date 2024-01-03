//
// Copyright (C) 2012 - present Instructure, Inc.
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

// #
// Validates a form, returns true or false, stores errors on element data.
//
// Markup supported:
//
// - Required
//   <input type="text" name="whatev" required>
//
// ex:
//   if $form.validates()
//     doStuff()
//   else
//     errors = $form.data 'errors'
import $ from 'jquery'
import {size} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('validate')

export default $.fn.validate = function () {
  const errors = {}

  this.find('[required]').each(function () {
    const $input = $(this)
    const name = $input.attr('name')
    const value = $input.val()
    if (value === '') {
      ;(errors[name] || (errors[name] = [])).push({
        name,
        type: 'required',
        message: I18n.t('is_required', 'This field is required'),
      })
    }
  })

  const hasErrors = size(errors) > 0
  if (hasErrors) {
    this.data('errors', errors)
    return false
  } else {
    this.data('errors', null)
    return true
  }
}

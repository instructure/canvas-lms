/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import preventDefault from '@canvas/util/preventDefault'
import '@canvas/jquery/jquery.instructure_forms' /* getFormData, formErrors */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf */
import '@canvas/user-sortable-name'

$(() => {
  const $registration_form = $('#registration_confirmation_form')
  const $disambiguation_box = $('.disambiguation_box')

  function showPane(paneToShow) {
    $.each([$disambiguation_box, $registration_form, $where_to_log_in], (i, $pane) =>
      $pane.showIf($pane.is(paneToShow))
    )
  }

  $('.btn#back').click(preventDefault(() => showPane($disambiguation_box)))

  $('.btn#register').click(preventDefault(() => showPane($registration_form)))

  const $merge_link = $('.btn#merge').click(event => {
    if ($merge_link.attr('href') === 'new_user_account') {
      showPane($registration_form)
      event.preventDefault()
    }
  })

  $('input:radio[name="pseudonym_select"]').change(() =>
    $merge_link.attr('href', $('input:radio[name="pseudonym_select"]:checked').prop('value'))
  )

  const $where_to_log_in = $('#where_to_log_in')

  if ($where_to_log_in.length) {
    $('#merge_if_clicked').click(() => {
      window.location = $merge_link.attr('href')
    })

    $merge_link.click(event => {
      event.preventDefault()
      showPane($where_to_log_in)
    })
  }

  $registration_form.find(':text:first').focus().select()
  $registration_form.formSubmit({
    disableWhileLoading: 'spin_on_success',
    errorFormatter: registrationErrors,
    success: data => (window.location.href = data.url || '/'),
  })
})

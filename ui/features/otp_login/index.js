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
import ready from '@instructure/ready'
import 'jquery-fancy-placeholder'

ready(() => {
  $('.field-with-fancyplaceholder input').fancyPlaceholder()
  $('#login_form').find(':text:first').select()

  const $select_phone_form = $('#select_phone_form')
  const $new_phone_form = $('#new_phone_form')
  const $phone_select = $select_phone_form.find('select')
  $phone_select.change(() => {
    if ($phone_select.val() === '{{id}}') {
      $select_phone_form.hide()
      $new_phone_form.show()
    }
  })

  $('#back_to_choose_number_link').click(event => {
    $new_phone_form.hide()
    $select_phone_form.show()
    $phone_select.find('option:first').prop('selected', true)
    event.preventDefault()
  })
})

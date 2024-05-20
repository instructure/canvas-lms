/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import {firstNameFirst, lastNameFirst, nameParts} from './user_utils'

$(function () {
  const $short_name = $('input[name="user[short_name]"]')
  // Sometimes user[name] is used for search forms on the same page as edit forms;
  // so find the name by starting with the short_name
  const $name = $short_name.parents('form').find('input[name="user[name]"]')
  const $sortable_name = $('input[name="user[sortable_name]"]')
  let prior_name = $name.prop('value')
  $name.keyup(function () {
    const name = $name.prop('value')
    const sortable_name = $sortable_name.prop('value')
    const sortable_name_parts = nameParts(sortable_name)
    if (
      $.trim(sortable_name) === '' ||
      firstNameFirst(sortable_name_parts) === $.trim(prior_name)
    ) {
      const parts = nameParts(name, sortable_name_parts[1])
      $sortable_name.prop('value', lastNameFirst(parts))
    }
    const short_name = $short_name.prop('value')
    if ($.trim(short_name) === '' || short_name === prior_name) {
      $short_name.prop('value', name)
    }
    prior_name = $(this).prop('value')
  })
})

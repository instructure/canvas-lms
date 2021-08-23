//
// Copyright (C) 2014 - present Instructure, Inc.
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

import 'jqueryui/autocomplete'

const $select_name = $('#select_name')
const $selected_name = $('#selected_name')
$('#account_select')
  .change(function() {
    $('.account_search').hide()
    $(`#account_search_${$(this).val()}`).show()
  })
  .change()

export default $('.account_search .user_name').each(function() {
  const $input = $(this)
  $input.autocomplete({
    minLength: 4,
    source: $input.data('autocompleteSource')
  })
  return $input.bind('autocompleteselect autocompletechange', (event, ui) => {
    if (ui.item) {
      $selected_name.text(ui.item.label)
      $select_name
        .show()
        .attr('href', $.replaceTags($('#select_name').attr('rel'), 'id', ui.item.id))
    } else {
      $select_name.hide()
    }
  })
})

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  "jquery",
  'jqueryui/autocomplete'
], ($) ->
  $select_name = $("#select_name")
  $selected_name = $("#selected_name")
  $("#account_select").change(->
    $(".account_search").hide()
    $("#account_search_" + $(this).val()).show()
  ).change()
  $(".account_search .user_name").each ->
    $input = $(this)
    $input.autocomplete
      minLength: 4
      source: $input.data("autocompleteSource")
    $input.bind "autocompleteselect autocompletechange", (event, ui) ->
      if ui.item
        $selected_name.text ui.item.label
        $select_name.show().attr "href", $.replaceTags($("#select_name").attr("rel"), "id", ui.item.id)
      else
        $select_name.hide()

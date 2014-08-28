require [
  "jquery",
  'compiled/behaviors/autocomplete'
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
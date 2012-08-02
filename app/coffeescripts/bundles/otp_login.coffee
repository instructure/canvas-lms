require [
  'jquery',
  'jquery.fancyplaceholder'
], ($) ->

  $(".field-with-fancyplaceholder input").fancyPlaceholder()
  $("#login_form").find(":text:first").select()

  $select_phone_form = $("#select_phone_form")
  $new_phone_form = $("#new_phone_form")
  $phone_select = $select_phone_form.find("select")
  $phone_select.change (event) ->
    if $phone_select.val() == '{{id}}'
      $select_phone_form.hide()
      $new_phone_form.show()

  $("#back_to_choose_number_link").click (event) ->
    $new_phone_form.hide()
    $select_phone_form.show()
    $phone_select.find("option:first").attr("selected", "selected")
    event.preventDefault()
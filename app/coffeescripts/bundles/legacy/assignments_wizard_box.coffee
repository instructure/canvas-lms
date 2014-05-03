require [
  "jquery",
  "jquery.instructure_misc_plugins",
  "vendor/jquery.scrollTo"
], ($) ->
  $(document).ready ->
    $(document).bind("add_assignment", ->
      $("#wizard_box .edit_assignment_option").click()  if $("#wizard_box .option.create_assignment_option.selected").length > 0
    ).bind "assignment_update", ->
      $("#wizard_box .review_assignment_option").click()  if $("#wizard_box .option.edit_assignment_option.selected").length > 0

    $(".highlight_add_assignment_icon").hover (->
      $link = $(".assignment_group:visible:first").find(".add_assignment_link")
      $(".no_groups_message").show()  if $link.length is 0
      $("html,body").scrollTo $link
      $link.indicate()
    ), ->
      $(".no_groups_message").hide()

    $(".highlight_add_assignment_group_icon").hover (->
      $link = $(".add_group_link:visible:first")
      $("html,body").scrollTo $link
      $link.indicate()
    ), ->

    $(".highlight_weight_groups").hover (->
      $item = $("#class_weighting_box")
      $("html,body").scrollTo $item
      $item.indicate()
    ), ->
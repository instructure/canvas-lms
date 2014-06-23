require [
  "jquery",
  'compiled/userSettings',
  "jquery.instructure_misc_plugins",
  "vendor/jquery.scrollTo"
], ($, userSettings) ->
  $(document).ready ->
    $(document).bind("add_assignment", ->
      $("#wizard_box .edit_assignment_option").click()  if $("#wizard_box .option.create_assignment_option.selected").length > 0
    ).bind "assignment_update", ->
      $("#wizard_box .review_assignment_option").click()  if $("#wizard_box .option.edit_assignment_option.selected").length > 0

    closeWizard = ->
      pathname = window.location.pathname
      userSettings.set('hide_wizard_' + pathname, true)
      $("#wizard_box").slideUp('fast')
      $(".wizard_popup_link").slideDown('fast')
      $("#wizard_spacer_box").height($("#wizard_box").height() || 0)

    screenreaderFocus = (elem) ->
      $("html,body").scrollTo elem
      closeWizard()
      elem.focus()

    $(".highlight_add_assignment_icon").hover (->
      $link = $(".assignment_group:visible:first").find(".add_assignment_link")
      $(".no_groups_message").show() if $link.length is 0
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

    $(".show_me_add_assignment_group").click (e) ->
      e.preventDefault()
      screenreaderFocus $(".add_group_link:visible:first")

    $(".show_me_weight_final_grade").click (e) ->
      e.preventDefault()
      screenreaderFocus $("#class_weighting_policy")

    $(".show_me_add_assignment").click (e) ->
      e.preventDefault()
      $link = $(".assignment_group:visible:first").find(".add_assignment_link")
      if $link.length is 0
        $(".no_groups_message").show()
      else
        screenreaderFocus $link

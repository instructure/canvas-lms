require [
  "jquery",
  "jquery.instructure_misc_plugins"
], ($, _miscPlugins) ->
  $(document).ready ->
    $("#wizard_box").addClass("wizard-box--course").bind "wizard_opened", ->
      $(this).find(".option.intro").click()

    $("#wizard_box").click (event) ->
      $(this).find(".option.intro").click()  if $(event.target).closest("a,li,input,.wizard_details").length is 0

    $(".change_home_page_layout_indicate").mouseover ->
      $(".edit_course_home_content_link").indicate()

    $(".wizard_options_list .option .header").mouseover (event) ->
      $(this).parents(".option").click()
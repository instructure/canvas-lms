require [
  "jquery",
  "jquery.instructure_misc_plugins"
], ($) ->
  $(document).ready ->
    $(".sections_list_hover").mouseover ->
      $("#section_list .section:first").indicate()

    $(".pages_list_hover").mouseover ->
      $("#section_pages").indicate()

    $(".organize_sections_hover").mouseover ->
      $(".manage_sections_link").indicate()

    $(".organize_pages_hover").mouseover ->
      $(".manage_pages_link").indicate()

    $(".eportfolio_settings_hover").mouseover ->
      $(".portfolio_settings_link").indicate()

    $(".edit_content_hover").mouseover ->
      $(".edit_content_link").indicate()

    $(".page_settings_hover").mouseover ->
      $("#edit_page_form .form_content").indicate()

    $(".page_buttons_hover").mouseover ->
      $("#edit_page_sidebar .form_content:last").indicate()

    $(".page_add_subsection_hover").mouseover ->
      $("#edit_page_sidebar ul").indicate()

    $("#wizard_box").bind "wizard_opened", ->
      $(this).find(".option.information_step").click()

    $(document).bind "submission_dialog_opened", ->
      $(".wizard_options .option.adding_submissions_dialog").click()  if $(".wizard_options .option.adding_submissions").hasClass("selected")

    $(document).bind "editing_page", ->
      $(".wizard_options .option.editing_mode").click()  if $(".wizard_options .option.edit_step").hasClass("selected")



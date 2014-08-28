require [
  "i18n!rubrics.index",
  "jquery",
  "find_outcome",
  "jquery.instructure_misc_plugins"
], (I18n, $) ->
  $(document).ready ->
    $("#rubrics ul .delete_rubric_link").click (event) ->
      event.preventDefault()
      $rubric = $(this).parents("li")
      $rubric.confirmDelete
        url: $(this).attr("href")
        message: I18n.t("are_you_sure_prompt", "Are you sure you want to delete this rubric? Any course currently associated with this rubric will still have access to it, but, no new courses will be able to use it.")
        success: ->
          $(this).slideUp ->
            $(this).remove()
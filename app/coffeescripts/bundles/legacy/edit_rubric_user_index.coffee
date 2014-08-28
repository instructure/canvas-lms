require [
  "i18n!rubrics.user_index",
  "jquery",
  "find_outcome",
  "jquery.instructure_misc_plugins"
], (I18n, $) ->
  $(document).ready ->
    $("#rubrics ul .delete_rubric_link").click (event) ->
      event.preventDefault()
      $rubric = $(this).parents("li")
      message = I18n.t("prompts.are_you_sure_delete", "Are you sure you want to delete this rubric? Any course currently associated with this rubric will still have access to it, but, no new courses will be able to use it.")
      message = I18n.t("prompts.are_you_sure_remove", "Are you sure you want to remove this rubric from your list?") if $(this).hasClass("remove_link")
      $rubric.confirmDelete
        url: $(this).attr("href")
        message: message
        success: ->
          $(this).slideUp ->
            $(this).remove()





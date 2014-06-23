require [
  "i18n!rubrics.show",
  "jquery",
  "jquery.instructure_misc_plugins"
], (I18n, $) ->
  $(document).ready ->
    $("#right-side .edit_rubric_link").click (event) ->
      event.preventDefault()
      $(".rubric:visible:first .edit_rubric_link").click()

    $("#right-side .delete_rubric_link").click (event) ->
      event.preventDefault()
      callback = ->
        location.href = $(".rubrics_url").attr("href")

      callback.confirmationMessage = I18n.t("prompts.are_you_sure_delete", "Are you sure you want to delete this rubric? Any course currently associated with this rubric will still have access to it, but, no new courses will be able to use it.")
      $(".rubric:visible:first .delete_rubric_link").triggerHandler "click", callback

    $(document).fragmentChange (event, hash) ->
      $("#right-side .edit_rubric_link").click() if hash is "#edit"



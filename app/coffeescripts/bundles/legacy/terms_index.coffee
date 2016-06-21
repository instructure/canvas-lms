require [
  "i18n!terms.index",
  "jquery",
  "jquery.instructure_date_and_time", # $.dateString, date_field
  "jquery.instructure_forms",
  "jquery.instructure_misc_helpers",
  "jquery.instructure_misc_plugins",
  "jquery.templateData"
], (I18n, $) ->
  $(document).ready ->
    $(".edit_term_link").click (event) ->
      event.preventDefault()
      $(this).parents(".term").addClass "editing_term"
      $(this).parents(".term").find(":text:visible:first").focus().select()
      $(this).parents(".term").find(".date_field").not(".already_has_date_field").addClass("already_has_date_field").date_field()

    $(".term .cancel_button").click ->
      $term = $(this).closest(".term")
      $term.removeClass "editing_term"
      if $term.attr("id") is "term_new"
        $term.remove()
        $(".add_term_link").focus()
      else
        $(".edit_term_link", $term).focus()

    $(".cant_delete_term_link").click (event) ->
      event.preventDefault()
      alert I18n.t("messages.classes_in_term", "You can't delete a term that still has classes in it.")

    $(".delete_term_link").click (event) ->
      event.preventDefault()
      $term = $(this).closest(".term")
      $focusTerm = $term.prev()
      $focusTerm = $term.next() unless $focusTerm.length
      $toFocus = if $focusTerm.length then $(".delete_term_link,.cant_delete_term_link", $focusTerm) else $(".add_term_link")
      url = $term.find(".enrollment_term_form").attr("action")
      $term.confirmDelete
        url: url
        message: I18n.t("prompts.delete", "Are you sure you want to delete this term?")
        success: ->
          $(this).fadeOut ->
            $(this).remove()
            $toFocus.focus()

    $(".enrollment_term_form").formSubmit
      processData: (data) ->
        permissions = $(this).parents("tr").find(".permissions").getFormData(object_name: "enrollment_term")
        $.extend permissions, data

      beforeSubmit: (data) ->
        $(this).find("button").attr "disabled", true
        $(this).find(".submit_button").text I18n.t("messages.submitting", "Submitting...")

      success: (data) ->
        term = data.enrollment_term
        $tr = $(this).parents(".term")
        $(this).find("button").attr "disabled", false
        $(this).find(".submit_button").text I18n.t("update_term", "Update Term")
        url = $.replaceTags($(".term_url").attr("href"), "id", term.id)
        $(this).attr "action", url
        $(this).attr "method", "PUT"
        for idx of term.enrollment_dates_overrides
          override = term.enrollment_dates_overrides[idx].enrollment_dates_override
          type_string = $.underscore(override.enrollment_type)
          # Student enrollments without an overridden start date get the term's overall start date, while teacher, ta,
          # and designer roles without an overridden start date allow access from the dawn of time. The logic
          # implementing this is in EnrollmentTerm#enrollment_dates_for.
          if override.start_at
            start_string = $.dateString(override.start_at)
          else if type_string == "student_enrollment"
            start_string = I18n.t("term start")
          else
            start_string = I18n.t("whenever")
          term[type_string + "_start_at"] = start_string
          # Non-overridden end dates always inherit the term end date, no matter the role.
          term[type_string + "_end_at"] = $.dateString(override.end_at) or I18n.t("date.term_end", "term end")
          term["enrollment_term[overrides][" + type_string + "][start_at]"] = $.dateString(override.start_at)
          term["enrollment_term[overrides][" + type_string + "][end_at]"] = $.dateString(override.end_at)
        term.start_at = $.dateString(term.start_at) or I18n.t("date.unspecified", "whenever")
        term.end_at = $.dateString(term.end_at) or I18n.t("date.unspecified", "whenever")
        $tr.fillTemplateData data: term
        $tr.attr "id", "term_" + term.id
        $tr.fillFormData data,
          object_name: "enrollment_term"

        $tr.removeClass "editing_term"
        $(".edit_term_link", $tr).focus()

      error: (data) ->
        $(this).find("button").attr "disabled", false
        $(this).formErrors data
        $(this).find(".submit_button").text I18n.t("errors.submit", "Error Submitting")
        $(".edit_term_link", $(this).closest("term")).focus()

    $(".add_term_link").click (event) ->
      event.preventDefault()
      return  if $("#term_new").length > 0
      $term = $("#term_blank").clone(true).attr("id", "term_new")
      $("#terms").prepend $term.show()
      $term.find(".edit_term_link").click()

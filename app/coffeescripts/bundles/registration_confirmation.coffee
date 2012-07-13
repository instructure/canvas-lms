require [
  "i18n!registration_confirmation"
  "jquery"
  "jquery.instructure_forms" #/* getFormData, formErrors */
  'jquery.instructure_misc_plugins' #/* showIf */
  'user_sortable_name'
], (I18n, $) ->
  $ ->
    $registration_form = $("#registration_confirmation_form")
    $disambiguation_box = $(".disambiguation_box")

    showPane = (paneToShow) ->
      $.each [$disambiguation_box, $registration_form, $where_to_log_in], (i, $pane) ->
        $pane.showIf $pane.is(paneToShow)

    $(".button#back").click (event) ->
      showPane($disambiguation_box)
      event.preventDefault()

    $(".button#register").click (event) ->
      showPane($registration_form)
      event.preventDefault()

    $merge_link = $(".button#merge").click (event) ->
      if $merge_link.attr('href') == 'new_user_account'
        showPane($registration_form)
        event.preventDefault()

    $("input:radio[name=\"pseudonym_select\"]").change ->
      $merge_link.attr "href", $("input:radio[name=\"pseudonym_select\"]:checked").attr("value")

    $where_to_log_in = $('#where_to_log_in')

    if $where_to_log_in.length
      $('#merge_if_clicked').click ->
        window.location = $merge_link.attr "href"

      $merge_link.click (event) ->
        event.preventDefault()
        showPane $where_to_log_in

    $registration_form.find(":text:first").focus().select()
    $registration_form.submit (event) ->
      data = $registration_form.getFormData()
      success = true
      if !data["pseudonym[password]"] || !data["pseudonym[password]"].length
        $registration_form.formErrors "pseudonym[password]": I18n.t("#pseudonyms.registration_confirmation_form.errors.password_required", "Password required")
        success = false
      else if data["pseudonym[password]"].length < 6
        $registration_form.formErrors "pseudonym[password]": I18n.t("#pseudonyms.registration_confirmation_form.errors.password_too_short", "Password too short")
        success = false
      success
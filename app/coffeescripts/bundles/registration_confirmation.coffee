require [
  "jquery"
  "compiled/registration/registrationErrors"
  "jquery.instructure_forms" #/* getFormData, formErrors */
  'jquery.instructure_misc_plugins' #/* showIf */
  'user_sortable_name'
], ($, registrationErrors) ->
  $ ->
    $registration_form = $("#registration_confirmation_form")
    $disambiguation_box = $(".disambiguation_box")

    showPane = (paneToShow) ->
      $.each [$disambiguation_box, $registration_form, $where_to_log_in], (i, $pane) ->
        $pane.showIf $pane.is(paneToShow)

    $(".btn#back").click (event) ->
      showPane($disambiguation_box)
      event.preventDefault()

    $(".btn#register").click (event) ->
      showPane($registration_form)
      event.preventDefault()

    $merge_link = $(".btn#merge").click (event) ->
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
    $registration_form.formSubmit
      disableWhileLoading: 'spin_on_success'
      errorFormatter: registrationErrors
      success: (data) ->
        location.href = data.url ? '/'

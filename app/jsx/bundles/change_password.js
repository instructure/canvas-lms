require [
  'jquery'
  'compiled/registration/registrationErrors'
  'jquery.instructure_forms'
], ($, registrationErrors) ->

  $form = $('#change_password_form')
  $form.formSubmit
    disableWhileLoading: 'spin_on_success'
    errorFormatter: (errors) ->
      pseudonymId = $form.find("#pseudonym_id_select").val()
      registrationErrors(errors, ENV.PASSWORD_POLICIES[pseudonymId] ? ENV.PASSWORD_POLICY)
    success: ->
      location.href = '/'
    error: (errors) ->
      location.href = '/login' if errors.nonce


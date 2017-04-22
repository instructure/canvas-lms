import $ from 'jquery'
import registrationErrors from 'compiled/registration/registrationErrors'
import 'jquery.instructure_forms'

const $form = $('#change_password_form')
$form.formSubmit({
  disableWhileLoading: 'spin_on_success',
  errorFormatter (errors) {
    const pseudonymId = $form.find('#pseudonym_id_select').val()
    return registrationErrors(errors, ENV.PASSWORD_POLICIES[pseudonymId] != null ? ENV.PASSWORD_POLICIES[pseudonymId] : ENV.PASSWORD_POLICY)
  },
  success () {
    location.href = '/'
  },
  error (errors) {
    if (errors.nonce) location.href = '/login'
  }
})

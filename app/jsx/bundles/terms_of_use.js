import $ from 'jquery'
import I18n from 'i18n!terms_of_use'
import 'jquery.instructure_forms'

$('form.reaccept_terms').submit(function () {
  const checked = !!($('input[name="user[terms_of_use]"]').is(':checked'))
  if (!checked) {
    $(this).formErrors({'user[terms_of_use]': I18n.t('You must agree to the terms')})
  }
  return checked
})

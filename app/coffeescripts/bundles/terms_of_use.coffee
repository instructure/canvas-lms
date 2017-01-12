require [
  'jquery'
  'i18n!terms_of_use'
  'jquery.instructure_forms'
], ($, I18n) ->

  $("form.reaccept_terms").submit ->
    checked = !!($('input[name="user[terms_of_use]"]').is(':checked'))
    unless checked
      $(this).formErrors('user[terms_of_use]': I18n.t("You must agree to the terms"))
    checked
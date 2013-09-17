require [
  'jquery'
  'compiled/models/User'
  'jquery.instructure_forms'
], ($, User) ->

  $('.reaccept_terms').formSubmit
    success: -> location.reload()
    errorFormatter: User::normalizeErrors.bind(User.prototype)

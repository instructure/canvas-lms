##
# Validates a form, returns true or false, stores errors on element data.
#
# Markup supported:
#
# - Required
#   <input type="text" name="whatev" required>
#
# ex:
#   if $form.validates()
#     doStuff()
#   else
#     errors = $form.data 'errors'
define [
  'jquery'
  'underscore'
  'i18n!validate'
], ($, _, I18n) ->

  $.fn.validate = ->
    errors = {}

    this.find('[required]').each ->
      $input = $ this
      name = $input.attr 'name'
      value = $input.val()
      if value is ''
        (errors[name] ?= []).push
          name: name
          type: 'required'
          message: I18n.t 'is_required', 'This field is required'

    hasErrors = _.size(errors) > 0

    if hasErrors
      this.data 'errors', errors
      false
    else
      this.data 'errors', null
      true


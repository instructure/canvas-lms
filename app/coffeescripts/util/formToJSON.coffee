define ['jquery'], ($) ->

  ##
  # Returns the form's values as key:value pairs
  # It's not actually a JSON string, its an object.
  formToJSON = ($form) ->
    json = {}
    array = $form.serializeArray()
    for item in array
      json[item.name] = item.value
    json

  ##
  # jQuery API
  $.fn.toJSON = ->
    formToJSON @first()

  formToJSON


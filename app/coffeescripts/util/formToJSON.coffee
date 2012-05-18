define ['jquery'], ($) ->

  ##
  # Returns the form's values as key:value pairs
  # It's not actually a JSON string, its an object.
  formToJSON = ($form) ->
    json = {}
    array = $form.serializeArray()
    for item in array

      # second time around, change the type to an array and add the old value to it
      if json[item.name]?
        if typeof json[item.name] is 'string'
          oldValue = json[item.name]
          json[item.name] = []
          json[item.name].push oldValue
        json[item.name].push item.value

      else
        json[item.name] = item.value

    json

  ##
  # jQuery API
  $.fn.toJSON = ->
    formToJSON @first()

  formToJSON


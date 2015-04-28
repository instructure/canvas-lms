# an extraction of the deparam method from Ben Alman's jQuery BBQ
# http://benalman.com/projects/jquery-bbq-plugin/

define ['compiled/object/unflatten'], (unflatten) ->

  coerceTypes =
    'true': true
    'false': false
    'null': null

  deparam = (params, coerce) ->
    # shortcut for just deparam'ing the current querystring
    if !params or typeof params == 'boolean'
      currentQueryString = window.location.search
      return {} unless currentQueryString
      return deparam currentQueryString, arguments...

    obj = {}

    params = params.replace(/^\?/, '')
    # Iterate over all name=value pairs.
    for param in params.replace(/\+/g, " ").split("&")
      [key, val] = param.split '='
      key = decodeURIComponent(key)
      val = decodeURIComponent(val)

      # coerce values.
      if coerce
        val = if val && !isNaN(val)
                +val #number
              else if val == 'undefined'
                undefined #undefined
              else if coerceTypes[val] != undefined
                coerceTypes[val] #true, false, null
              else
                val #string

      obj[key] = val

    unflatten obj

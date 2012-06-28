# turns {foo: {bar: 1}} into {'foo[bar]': 1}
define ->
  flatten = (obj, options = {}, result = {}, prefix) ->
    for key, value of obj
      key = if prefix then "#{prefix}[#{key}]" else key
      flattenable = (typeof value is 'object')
      flattenable = false if value.length? and options.arrays is false
      if flattenable
        flatten(value, options, result, key)
      else
        result[key] = value
    result
define ['ember'], (Ember) ->

  # THERE HAS TO BE SOMEWHERE ELSE IN OUR APP THAT DOES THIS
  # TODO: find it and use that instead.

  # converts bytes into a nice representation with unit. e.g. 13661855 -> 13.7 MB, 825399 -> 825 KB, 1396 -> 1 KB
  Ember.Handlebars.registerHelper 'friendlyBytes', (value, {contexts:[context]}) ->

    # this line seems crazy and weird to have to do!
    value = Ember.get(context, value)

    bytes = parseInt(value, 10)
    if bytes.toString() is 'NaN'
      console.error "Handlebars helper friendlyBytes couldn't parse '#{value}'"
      return value
    metric = ['byte', 'bytes', 'KB', 'MB', 'GB'] # KB is technically a Kilobit, but it seems more readable. YOLO

    if bytes is 0
      resInt = resValue = 0
    else
      resInt = Math.floor(Math.log(bytes) / Math.log(1000)) # base 10 (rather than 1024) matches Mac OS X
      resValue = (bytes / Math.pow(1000, Math.floor(resInt))).toFixed(if resInt < 2 then 0 else 1) # no decimals for anything smaller than 1 MB
      resInt = -1 if bytes is 1 # 1 byte special case

    return new Handlebars.SafeString( resValue + ' ' + metric[resInt + 1] )
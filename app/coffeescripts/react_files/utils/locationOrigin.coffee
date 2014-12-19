define [], () ->
  # locationOrigin.coffee
  #
  # A slight modification of location-origin.js
  # https://github.com/shinnn/location-origin.js
  'use strict'

  loc = window.location

  return if loc.origin

  value = loc.protocol + '//' + loc.hostname + if loc.port then ':' + loc.port else ''

  try
    Object.defineProperty loc, 'origin', {value, enumerable: true}
  catch e
    loc.origin = value
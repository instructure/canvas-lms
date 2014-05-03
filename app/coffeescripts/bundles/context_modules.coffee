require [
  'jquery'
  'context_modules'
], ($) ->

  if ENV.NO_MODULE_PROGRESSIONS
    $('.module_progressions_link').remove()

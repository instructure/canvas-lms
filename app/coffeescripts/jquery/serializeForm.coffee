define [
  'jquery'
  'underscore'
], ($, _) ->
  rselectTextarea = /^(?:select|textarea)/i
  rcheckboxOrRadio = /checkbox|radio/i
  rCRLF = /\r?\n/g
  rinput = /^(?:color|date|datetime|datetime-local|email|hidden|month|number|password|range|search|tel|text|time|url|week|checkbox|radio|file)$/i

  isInput = (el) ->
    el.name && !el.disabled && rselectTextarea.test(el.nodeName) or rinput.test(el.type)

  getValue = (el) ->
    resultFor = (val) ->
      name: el.name
      el: el
      value: if _.isString(val) then val.replace( rCRLF, "\r\n" ) else val

    $input = $(el)
    val = if rcheckboxOrRadio.test(el.type)
      el.checked
    else if el.type == 'file'
      el if $input.val()
    else if $input.hasClass 'datetime_field_enabled'
      # datepicker doesn't clear the data date attribute when a date is deleted
      if $input.val() == ""
        null
      else
        $input.data('date') || null
    else if $input.data('rich_text')
      $input.editorBox('get_code', false)
    else
      $input.val()

    if _.isArray val
      _.map val, resultFor
    else
      resultFor val


  $.fn.serializeForm = ->
    _.chain(this[0].elements || this.find(':input'))
      .filter(isInput)
      .map(getValue)
      .value()

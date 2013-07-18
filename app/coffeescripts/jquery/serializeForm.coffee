define [
  'jquery'
  'underscore'
], ($, _) ->
  $.fn.serializeForm = ->
    rselectTextarea = /^(?:select|textarea)/i
    rcheckboxOrRadio = /checkbox|radio/i
    rradio = /(?:radio)/i
    rCRLF = /\r?\n/g
    rinput = /^(?:color|date|datetime|datetime-local|email|hidden|month|number|password|range|search|tel|text|time|url|week|checkbox|radio|file)$/i

    isInput = (el) ->
      el.name && !el.disabled && rselectTextarea.test(el.nodeName) or rinput.test(el.type)

    isRadioChecked = (el) ->
      !rradio.test(el.type) || $(el).is(':checked')

    if this.is('[serialize-radio-value]')
      rcheckboxOrRadio = /checkbox/i # return val for radio boxes
      rRadio = /radio/i

      _isInput = isInput
      isInput = (el) -> # only include the checked radio input
        _isInput(el) && (!rRadio.test(el.type) || el.checked)

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

    _.chain(this[0].elements || this.find(':input'))
      .filter(isInput)
      .filter(isRadioChecked)
      .map(getValue)
      .value()

define ['jquery'], ($) ->

  rselectTextarea = /^(?:select|textarea)/i
  rCRLF = /\r?\n/g
  rinput = /^(?:color|date|datetime|datetime-local|email|hidden|month|number|password|range|search|tel|text|time|url|week|file)$/i
  # radio / checkbox are not included, since they are handled by the @checked check

  elements = ->
    if @elements
      $.makeArray @elements
    else
      elements = $(this).find(':input')
      if elements.length
        elements
      else
        this

  isSerializable = ->
    @name and not @disabled and (
      @checked or
      rselectTextarea.test(@nodeName) or
      rinput.test(@type)
    )

  resultFor = (name, value) ->
    value = value.replace(rCRLF, "\r\n") if typeof value is 'string'
    {name, value}

  getValue = ->
    $input = $(this)
    value = if @type == 'file'
      this if $input.val()
    else if $input.hasClass 'datetime_field_enabled'
      # datepicker doesn't clear the data date attribute when a date is deleted
      if $input.val() is ""
        null
      else
        $input.data('date') or null
    else if $input.data('rich_text')
      $input.editorBox('get_code', false)
    else
      $input.val()

    if $.isArray(value)
      resultFor(@name, val) for val in value
    else
      resultFor(@name, value)

  ##
  # identical to $.fn.serializeArray, except:
  # 1. it works on non-forms (see elements)
  # 2. it handles file, date picker and tinymce inputs (see getValue)
  $.fn.serializeForm = ->
    @map(elements)
      .filter(isSerializable)
      .map(getValue)
      .get()


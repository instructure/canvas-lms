define [
  'jquery'
  'jquery.toJSON'
], ($) ->

  # TODO: share code with 'unflatten' module

  $datepickerEl = ->
    $ """
      <input type='text' name='date' class='datetime_field_enabled'/>
    """

  QUnit.module 'jquery.toJSON',
    setup: ->
      @form = $ '<form/>'
      @form.html """
        <input type="text" name="foo"               value="foo">
        <input type="text" name="arr[]"             value="1">
        <input type="text" name="arr[]"             value="2">
        <input type="text" name="nested[foo]"       value="nested[foo]">
        <input type="text" name="nested[bar]"       value="nested[bar]">
        <input type="text" name="nested[baz][qux]"  value="nested[baz][qux]">
        <input type="text" name="nested[arr][]"     value="1">
        <input type="text" name="nested[arr][]"     value="2">
      """

  test "serializes to a JSON string correctly", ->
    expected =
      foo: 'foo'
      arr: ['1','2']
      nested:
        foo: 'nested[foo]'
        bar: 'nested[bar]'
        baz:
          qux: 'nested[baz][qux]'
        arr: ['1','2']
    equal JSON.stringify(expected), JSON.stringify(@form)

  test """
    returns null if element with datetime_field enabled class has undefined
    for $.data( 'date' )
  """, ->
    @form.prepend $datepickerEl()
    strictEqual @form.toJSON().date, null

  test "returns date object for form element with datetime_field_enabled",->
    $dateEl = $datepickerEl()
    @form.prepend $dateEl
    date = Date.now()
    $dateEl.data 'date', date
    $dateEl.val(date)
    strictEqual @form.toJSON().date, date


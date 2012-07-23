define [
  'jquery'
  'formToJSON'
], ($, formToJSON) ->

  # TODO: share code with 'unflatten' module

  module 'formToJSON'

  test 'turns a form into an JSON object', ->

    form = $ '<form/>'
    form.html """
      <input type="text" name="foo"               value="foo">
      <input type="text" name="arr[]"             value="1">
      <input type="text" name="arr[]"             value="2">
      <input type="text" name="nested[foo]"       value="nested[foo]">
      <input type="text" name="nested[bar]"       value="nested[bar]">
      <input type="text" name="nested[baz][qux]"  value="nested[baz][qux]">
      <input type="text" name="nested[arr][]"     value="1">
      <input type="text" name="nested[arr][]"     value="2">
    """

    expected =
      foo: 'foo'
      arr: ['1','2']
      nested:
        foo: 'nested[foo]'
        bar: 'nested[bar]'
        baz:
          qux: 'nested[baz][qux]'
        arr: ['1','2']

    json = form.toJSON()

    equal     json.foo,             'foo'
    deepEqual json.arr,             ['1','2']
    equal     json.nested.foo,      'nested[foo]'
    equal     json.nested.bar,      'nested[bar]'
    equal     json.nested.baz.qux,  'nested[baz][qux]'
    deepEqual json.nested.arr,      ['1', '2']

    # make sure JSON.stringify($el) works
    equal JSON.stringify(expected), JSON.stringify(form)


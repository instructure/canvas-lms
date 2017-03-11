define ['jsx/external_apps/lib/classMunger'], (classMunger) ->
  QUnit.module 'ExternalApps.classMunger'

  test 'conditionally joins classes', ->
    cls = classMunger('foo', { 'bar': true, 'baz': false })
    equal cls, 'foo bar'

    cls = classMunger('foo', { 'bar': true, 'baz': true })
    equal cls, 'foo bar baz'

    cls = classMunger('foo fum', { 'bar': true, 'baz': false, 'bop': true })
    equal cls, 'foo fum bar bop'

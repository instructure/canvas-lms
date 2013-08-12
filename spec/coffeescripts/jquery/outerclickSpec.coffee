define [
  'jquery'
  'compiled/jquery/outerclick'
], ($) ->

  module 'outerclick'

  test 'should work', ->
    handler = sinon.spy()
    $doc = $(document)
    $foo = $('<b>hello <i>world</i></b>').appendTo($doc)
    $foo.on 'outerclick', handler
    $foo.click()
    $foo.find('i').click()
    ok !handler.called

    $doc.click()
    ok handler.calledOnce

    $foo.remove()


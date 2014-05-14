define [
  'jquery'
  'jquery.instructure_misc_plugins'
], (jQuery) ->
  $ = jQuery

  module 'instructure misc plugins'

  test 'showIf', ->
    el = $('<input type="checkbox" id="checkbox1">').appendTo("#fixtures")

    el.showIf(-> true)
    equal(el.is(":visible"), true, 'should show if callback returns true')

    el.showIf(-> false)
    equal(el.is(":visible"), false, 'should be hidden if callback returns false')

    el.showIf(true)
    equal(el.is(":visible"), true, 'should show if true as argument')
    el.showIf(false)
    equal(el.is(":visible"), false, 'should not show if false as argument')

    el.showIf(true)
    equal(el.is(":visible"), true)
    ok(el.showIf(-> true) is el)
    ok(el.showIf(-> false) is el)
    ok(el.showIf(true) is el)
    ok(el.showIf(false) is el)

    el.showIf ->
      ok(this.nodeType)
      notEqual(this.constructor, jQuery)

    el.remove()

  test 'disableIf', ->
    el = $('<input type="checkbox" id="checkbox1">').appendTo($("#fixtures"))

    el.disableIf(-> true)
    equal(el.is(":disabled"), true)

    el.disableIf(-> false)
    equal(el.is(":disabled"), false)

    el.disableIf(-> true)
    equal(el.is(":disabled"), true)

    el.disableIf(false)
    equal(el.is(":disabled"), false)

    el.disableIf(true)
    equal(el.is(":disabled"), true)
    equal(el.disableIf(-> true), el)
    equal(el.disableIf(-> false), el)
    equal(el.disableIf(true), el)
    equal(el.disableIf(false), el)

    el.remove()

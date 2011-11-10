define [
  'jquery'
  'helpers/loadFixture'
  'jquery.instructure_misc_plugins'
], (jQuery, loadFixture) ->

  module 'instructure misc plugins'

  test 'showIf', ->
    fixture = loadFixture "jQuery.instructureMiscPlugins"
    el = jQuery '#checkbox1'
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
    equal(el.showIf(-> true), el)
    equal(el.showIf(-> false), el)
    equal(el.showIf(true), el)
    equal(el.showIf(false), el)

    el.showIf ->
      ok(this.nodeType)
      notEqual(this.constructor, jQuery)

    fixture.remove()

  test 'disableIf', ->
    fixture = loadFixture "jQuery.instructureMiscPlugins"
    el = jQuery '#checkbox1'

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

    fixture.remove()

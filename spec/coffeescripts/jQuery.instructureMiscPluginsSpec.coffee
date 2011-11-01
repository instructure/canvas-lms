define [
  'js!vendor/jquery-1.6.4.js',
  'js!I18n.js',
  'js!jquery.instructure_misc_plugins.js!order'
], ->

  module 'instructure misc plugins'

  test 'showIf', ->
    loadFixture "jQuery.instructureMiscPlugins"
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

    removeFixture "jQuery.instructureMiscPlugins"

  test 'disableIf', ->
    loadFixture "jQuery.instructureMiscPlugins"
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

    removeFixture "jQuery.instructureMiscPlugins"

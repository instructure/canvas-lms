define [
  'jquery'
  'compiled/views/editor/KeyboardShortcuts'
], ($, KeyboardShortcuts)->


  view = null
  QUnit.module "editor KeyboardShortcuts",
    setup: ->
      view = new KeyboardShortcuts()
      view.$dialog = {
        opened: false,
        dialog: (cmd)->
          if cmd == 'open'
            @opened = true
      }
      view.bindEvents()

    teardown: ->
      view.remove()

  test "ALT+F8 should open the helpmenu", ->
    $(document).trigger("editorKeyUp", [{keyCode: 119, altKey: true}])
    equal(view.$dialog.opened, true)

  test "ALT+0 opens the helpmenu", ->
    $(document).trigger("editorKeyUp", [{keyCode: 48, altKey: true}])
    equal(view.$dialog.opened, true)

  test "ALT+0 (numpad) does not open the helpmenu (we need that for unicode entry on windows)", ->
    $(document).trigger("editorKeyUp", [{keyCode: 96, altKey: true}])
    equal(view.$dialog.opened, false)

  test "any of those help values without alt does nothing", ->
    $(document).trigger("editorKeyUp", [{keyCode: 119, altKey: false}])
    equal(view.$dialog.opened, false)

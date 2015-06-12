define [
  'jquery'
  'compiled/editor/stocktiny'
  'compiled/editor/editorAccessibility'
], ($, tinymce, EditorAccessibility)->

  fixtures = $("#fixtures")
  textarea = null
  acc = null
  activeEditorNodes = null

  module "EditorAccessibility",

    setup: ->
      textarea = $("<textarea id='42' data-rich_text='true'></textarea>")
      fixtures.append(textarea)
      tinymce.init({selector: "#fixtures textarea#42"})
      acc = new EditorAccessibility(tinymce.activeEditor)
      activeEditorNodes = tinymce.activeEditor.getContainer().children
    teardown: ->
      textarea.remove()
      fixtures.empty()
      acc = null
      activeEditorNodes = null

  test "initialization", ->
    equal(acc.$el.length, 1)

  test "cacheElements grabs the relevant tinymce iframe", ->
    acc._cacheElements()
    ok(acc.$iframe.length, 1)

  test "accessiblize() gives a helpful title to the iFrame", ->
    acc.accessiblize()
    equal($(acc.$iframe).attr('title'), "Rich Text Area. Press ALT+F8 for help")

  test "accessiblize() removes the statusbar from the tabindex", ->
    acc.accessiblize()
    statusbar = $(activeEditorNodes).find('.mce-statusbar > .mce-container-body')
    equal(statusbar.attr('tabindex'), "-1")

  test "accessibilize() hides the menubar, Alt+F9 shows it", ->
    acc.accessiblize()
    $menu = $(activeEditorNodes).find(".mce-menubar")
    equal($menu.is(":visible"), false)
    event = {
      isDefaultPrevented: (-> false),
      altKey: true,
      ctrlKey: false,
      metaKey: false,
      shiftKey: false,
      keyCode: 120, #<- this is F9
      preventDefault: (->),
      isImmediatePropagationStopped: (-> false)
    }

    tinymce.activeEditor.fire("keydown", event)
    equal($menu.is(":visible"), true)

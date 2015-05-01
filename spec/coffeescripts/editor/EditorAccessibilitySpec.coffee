define [
  'jquery'
  'compiled/editor/stocktiny'
  'compiled/editor/editorAccessibility'
], ($, tinymce, EditorAccessibility)->

  textarea = null

  module "EditorAccessibility",

    setup: ->
      fixture = $("#fixtures")
      textarea = $("<textarea id='42' data-rich_text='true'></textarea>")
      fixture.append(textarea)
      tinymce.init({selector: "#fixtures textarea#42"})

    teardown: ->
      textarea.remove()
      $("#fixtures").empty()

  test "initialization", ->
    acc = new EditorAccessibility(tinymce.activeEditor)
    equal(acc.$el.length, 1)

  test "cacheElements grabs the relevant tinymce iframe", ->
    acc = new EditorAccessibility(tinymce.activeEditor)
    acc._cacheElements()
    ok(acc.$iframe.length, 1)

  test "accessiblize() gives a helpful title to the iFrame", ->
    acc = new EditorAccessibility(tinymce.activeEditor)
    acc.accessiblize()
    equal($(acc.$iframe).attr('title'), "Rich Text Area. Press ALT+F8 for help")

  test "accessibilize() hides the menubar, Alt+F9 shows it", ->
    editor = tinymce.activeEditor
    acc = new EditorAccessibility(editor)
    acc.accessiblize()
    $menu = $(".mce-menubar")
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

    editor.fire("keydown", event)
    equal($menu.is(":visible"), true)

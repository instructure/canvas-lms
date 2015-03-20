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

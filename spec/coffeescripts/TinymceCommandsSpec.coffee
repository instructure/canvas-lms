define [
  'jquery'
  'compiled/editor/stocktiny'
  'tinymce.commands'
  'tinymce.editor_box_list'
],($,tinymce,EditorCommands,EditorBoxList)->

  list = null
  textarea = null

  module "Tinymce Commands -> removing an editor",
    setup: ->
      testbed = $("<div id='command-testbed'></div>")
      $("body").append(testbed)
      textarea = $("<textarea id='42' data-rich_text='true'></textarea>")
      testbed.append(textarea)
      list = new EditorBoxList()

    teardown: ->
      textarea.remove()
      $("#command-testbed").remove()

  test 'it un-rich-texts the DOM element', ->
    EditorCommands.remove(textarea, list)
    equal(textarea.data('rich_text'), false)

  test 'it causes tinymce to forget about the editor', ->
    tinymce.init({selector: "#command-testbed textarea#42"})
    equal(tinymce.activeEditor.id, '42')
    EditorCommands.remove(textarea, list)
    equal(undefined, tinymce.activeEditor)

  test 'it unregisters the editor from our global list', ->
    box = {}
    list._addEditorBox('42', box)
    equal(box, list._editor_boxes['42'])
    EditorCommands.remove(textarea, list)
    equal(undefined, list._editor_boxes['42'])


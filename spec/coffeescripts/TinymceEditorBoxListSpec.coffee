define ['tinymce.editor_box_list'], (EditorBoxList)->
  list = null
  module "EditorBoxList",
    setup: ->
      $("#fixtures").append("<textarea id=42></textarea>")
      list = new EditorBoxList()

    teardown: ->
      $("#42").remove()
      $("#fixtures").empty()

  test 'constructor: property setting', ->
    ok(list._textareas?)
    ok(list._editors?)
    ok(list._editor_boxes?)

  test 'adding an editor box to the list', ->
    box = {}
    node = $("#42")
    list._addEditorBox('42', box)
    equal(list._editor_boxes['42'], box)
    equal(list._textareas['42'].id, node.id)

  test "removing an editorbox from storage", ->
    list._addEditorBox('42', {})
    list._removeEditorBox('42')
    ok(!list._editor_boxes['42']?)
    ok(!list._textareas['42']?)

  test "retrieving a text area", ->
    node = $("#42")
    ok(list._getTextArea('42').id == node.id)

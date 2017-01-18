define [
  'jquery'
  'compiled/editor/stocktiny'
  'tinymce.commands'
  'tinymce.editor_box_list'
],($,tinymce,EditorCommands,EditorBoxList)->

  testbed = null
  list = null
  textarea = null

  module "Tinymce Commands -> removing an editor",
    setup: ->
      testbed = $("<div id='command-testbed'></div>")
      $("#fixtures").append(testbed)
      textarea = $("<textarea id='43' data-rich_text='true'></textarea>")
      testbed.append(textarea)
      list = new EditorBoxList()

    teardown: ->
      list = null
      testbed = null
      textarea.remove()
      $("#command-testbed").remove()
      $("#fixtures").empty()

  test 'it un-rich-texts the DOM element', ->
    EditorCommands.remove(textarea, list)
    equal(textarea.data('rich_text'), false)

  test 'it causes tinymce to forget about the editor', ->
    tinymce.init({selector: "#command-testbed textarea#43"})
    equal(tinymce.activeEditor.id, '43')
    EditorCommands.remove(textarea, list)
    equal(undefined, tinymce.activeEditor)

  test 'it unregisters the editor from our global list', ->
    box = {}
    list._addEditorBox('43', box)
    equal(box, list._editor_boxes['43'])
    EditorCommands.remove(textarea, list)
    equal(undefined, list._editor_boxes['43'])

  module "Tinymce Commands -> inserting content with tables",
    setup: ->
      testbed = $("<div id='command-testbed'></div>")
      $("#fixtures").append(testbed)

    teardown: ->
      textarea.remove()
      $("#command-testbed").remove()
      $("#fixtures").empty()
      testbed = null
      list = null

  test 'it keeps surrounding html when inserting links in a table', ->
    textarea = $("<textarea id='43' data-rich_text='true'>
    <table>
      <tr>
        <td><span id='span'><a id='link' href='#'>Test Link</a></span></td>
      </tr>
    </table>
    </textarea>")
    testbed.append(textarea)
    list = new EditorBoxList()
    tinymce.init({selector: "#command-testbed textarea#43"})
    editor = tinymce.get(43)

    editor.selection.select(editor.dom.select('a')[0])

    new_link_id = "new_link"
    linkAttr = {target: "", title: "New Link", href: "/courses/1/pages/blah", class: "", id: new_link_id}
    EditorCommands.insertLink(43, null, linkAttr)

    equal editor.selection.select(editor.dom.select('span')[0]).childNodes[0].id, new_link_id, "keeps surrounding span tag"

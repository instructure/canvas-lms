define [
  'jquery',
  'tinymce_plugins/instructure_links/linkable_editor'
], ($, LinkableEditor) ->

  rawEditor = null

  module "LinkableEditor",
    setup: ->
      $("#fixtures").html("<div id='some_editor' data-value='42'></div>")
      rawEditor = {
        id: 'some_editor',
        selection: {
          getContent: (()-> "Some Content")
        }
      }

    teardown: ->
      $("#fixtures").empty()

  test "can load the original element from the editor id", ->
    editor = new LinkableEditor(rawEditor)
    equal(editor.getEditor().data('value'), '42')

  test "shipping a new link to the editor instance", ->
    jqueryEditor = {editorBox: (()->) }
    editor = new LinkableEditor(rawEditor, jqueryEditor)
    text = "Link HREF"
    classes = ""
    expectedOpts = {
      url: text,
      classes: classes,
      selectedContent: "Some Content"
    }
    edMock = @mock(jqueryEditor)
    edMock.expects("editorBox").withArgs('create_link', expectedOpts)
    editor.createLink(text, classes)

  test "pulling out text content from a text node", ->
    editor = new LinkableEditor(rawEditor)
    extractedText = editor.extractTextContent({
      getContent: ((opts)-> "Plain Text")
    })
    equal(extractedText, "Plain Text")

  test "extracting text from an IMG node with firefox api", ->
    editor = new LinkableEditor(rawEditor)
    extractedText = editor.extractTextContent({
      getContent: ((opts)->
        if opts? and opts.format is "text"
          "alt_text"
        else
          "<img alt='alt_text' src=''/>"
      )
    })
    equal(extractedText, "")


define [
  'jquery'
  'wikiSidebar'
  'tinymce.editor_box'
  'compiled/tinymce'
], ($, wikiSidebar) ->

  $.subscribe 'editorBox/focus', ($editor) ->
    wikiSidebar.init() unless wikiSidebar.inited
    wikiSidebar.show()
    wikiSidebar.attachToEditor($editor)

  $.subscribe 'editorBox/removeAll', ->
    wikiSidebar.hide()
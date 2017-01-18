define [
  'jquery'
  'compiled/editor/EditorToggle'
  'compiled/discussions/EntryEditor'
  'jsx/shared/rce/RichContentEditor'
], ($, EditorToggle, EntryEditor, RichContentEditor) ->

  module 'EntryEditor'

  test 'createTextArea should add an id if there isn\'t one', ->
    @stub(EditorToggle.prototype, 'createTextArea').returns $('<textarea/>')
    result = EntryEditor::createTextArea()
    ok result.attr('id')

  test 'createTextArea should not change the id if there already is one', ->
    id = 'existingID'
    el = $('<textarea/>', {id})
    @stub(EditorToggle.prototype, 'createTextArea').returns el
    result = EntryEditor::createTextArea()
    equal result.attr('id'), id

  module 'EntryEditor',
    setup: ->
      @context =
        el: $('<li/>')
        textArea: $('<div/>')
      @stub $.fn, 'detach'
      @stub $.fn, 'insertBefore'
      @stub RichContentEditor, 'destroyRCE'
      @stub RichContentEditor, 'freshNode', ($target) =>
        @newTextArea = $target.clone()

  test 'display should insert the @el before the new textArea', ->
    EntryEditor::replaceTextArea.call @context
    firstCall = $.fn.insertBefore.firstCall
    ok firstCall.thisValue==@context.el, 'insertBefore called on @el'
    ok firstCall.args[0]==@newTextArea, 'insertBefore called with the newTextArea'

  test 'replaceTextArea should detach the new textArea', ->
    EntryEditor::replaceTextArea.call @context
    ok $.fn.detach.calledOn @newTextArea

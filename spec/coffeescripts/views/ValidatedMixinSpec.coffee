define [
  'jquery'
  'compiled/editor/stocktiny'
  'compiled/views/ValidatedMixin'
],($,tinymce,ValidatedMixin)->

  textarea = null
  QUnit.module "ValidatedMixin",
    setup: ->
      textarea = $("<textarea id='42' name='message' data-rich_text='true'></textarea>")
      $('#fixtures').append textarea
      ValidatedMixin.$ = $

    teardown: ->
      textarea.remove()
      $("#fixtures").empty()

  test 'it can find tinymce instances as fields', ->
    tinymce.init({selector: "#fixtures textarea#42"})
    element = ValidatedMixin.findField('message')
    equal(element.length, 1)

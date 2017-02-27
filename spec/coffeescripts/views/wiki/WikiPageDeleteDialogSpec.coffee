define [
  'compiled/models/WikiPage'
  'compiled/views/wiki/WikiPageDeleteDialog'
], (WikiPage, WikiPageDeleteDialog) ->

  QUnit.module 'WikiPageDeleteDialog'

  test 'maintains the view of the model', ->
    model = new WikiPage
    model.view = view = {}
    dialog = new WikiPageDeleteDialog
      model: model

    equal model.view, view, 'model.view is unaltered'

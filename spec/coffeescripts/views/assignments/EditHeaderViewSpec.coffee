define [
  'jquery'
  'underscore'
  'compiled/models/Assignment'
  'compiled/views/assignments/EditHeaderView'
  'helpers/fakeENV'
], ($, _, Assignment, EditHeaderView, fakeENV) ->

  defaultAssignmentOpts =
    name: 'Test Assignment'
    assignment_overrides: []

  editHeaderView = () ->
    assignment = new Assignment defaultAssignmentOpts

    app = new EditHeaderView
      model: assignment

    app.render()

  module 'EditHeaderView',
    setup: ->
      fakeENV.setup()
    teardown: ->
      fakeENV.teardown()

  test 'renders', ->
    view = editHeaderView()
    ok view.$('.header-bar-right').length > 0, 'header bar is rendered'

  test 'delete works for an un-saved assignment', ->
    view = editHeaderView()
    cb = sinon.stub(view, 'onDeleteSuccess')

    view.delete()
    equal cb.called, true, 'onDeleteSuccess was called'

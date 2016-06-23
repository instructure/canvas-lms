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

  editHeaderView = (assignment_opts = {}) ->
    $.extend(assignment_opts, defaultAssignmentOpts)
    assignment = new Assignment assignment_opts

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
    cb = @stub(view, 'onDeleteSuccess')

    view.delete()
    equal cb.called, true, 'onDeleteSuccess was called'

  test 'attaches conditional release editor', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
    view = editHeaderView()
    equal 1, view.$conditionalReleaseTarget.children().size()

  test 'disables conditional release tab on load when grading type is not_graded', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
    view = editHeaderView({ grading_type: 'not_graded' })
    equal true, view.$headerTabsCr.tabs('option', 'disabled')

  test 'enables conditional release tab when grading type switched from not_graded', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
    view = editHeaderView({ grading_type: 'not_graded' })
    view.onGradingTypeUpdate({target: { value: 'points' }})
    equal false, view.$headerTabsCr.tabs('option', 'disabled')

  test 'disables conditional release tab when grading type switched to not_graded', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
    view = editHeaderView({ grading_type: 'points' })
    view.onGradingTypeUpdate({target: { value: 'not_graded' }})
    equal true, view.$headerTabsCr.tabs('option', 'disabled')

  test 'disables conditional release component on data change', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
    view = editHeaderView({ grading_type: 'points' })
    view.onChange()
    equal false, view.$headerTabsCr.tabs('option', 'disabled')
    equal false, view.conditionalReleaseEditor.enabled()

  test 'disables conditional release component once', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
    view = editHeaderView({ grading_type: 'points' })
    stub = @stub(view.conditionalReleaseEditor, 'setProps')
    view.onChange()
    ok stub.calledOnce

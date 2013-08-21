define [
  'Backbone'
  'compiled/models/Assignment'
  'compiled/views/assignments/AssignmentListItemView'
  'jquery'
  'helpers/jquery.simulate'
], (Backbone, Assignment, AssignmentListItemView, $) ->
  screenreaderText = null
  nonScreenreaderText = null
  oldENV = window.ENV ||= {}

  fixtures = $('#fixtures')

  class AssignmentCollection extends Backbone.Collection
    model: Assignment

  assignment1 = ->
    date1 =
      "due_at":"2013-08-28T23:59:00-06:00"
      "title":"Summer Session"
    date2 =
      "due_at":"2013-08-28T23:59:00-06:00"
      "title":"Winter Session"

    ac = new AssignmentCollection [buildAssignment(
      "id":1
      "name":"History Quiz"
      "description":"test"
      "due_at":"2013-08-21T23:59:00-06:00"
      "points_possible":2
      "position":1
      "all_dates":[date1, date2]
    )]
    ac.at(0)

  assignment2 = ->
    ac = new AssignmentCollection [buildAssignment(
      "id":3
      "name":"Math Quiz"
      "due_at":"2013-08-23T23:59:00-06:00"
      "points_possible":10
      "position":2
    )]
    ac.at(0)

  assignment3 = ->
    ac = new AssignmentCollection [buildAssignment(
      "id":2
      "name":"Science Quiz"
      "points_possible":5
      "position":3
    )]
    ac.at(0)

  buildAssignment = (options) ->
    options ?= {}

    base =
      "assignment_group_id":1
      "due_at":null
      "grading_type":"points"
      "points_possible":5
      "position":2
      "course_id":1
      "name":"Science Quiz"
      "submission_types":[]
      "html_url":"http://localhost:3000/courses/1/assignments/#{options.id}"
      "needs_grading_count":0
      "all_dates":[]
      "published":true
    $.extend base, options

  createView = (model, options) ->
    options = $.extend {canManage: true}, options

    sinon.stub( AssignmentListItemView.prototype, "canManage", -> options.canManage )
    sinon.stub( AssignmentListItemView.prototype, "modules", -> )

    view = new AssignmentListItemView(model: model)
    view.$el.appendTo $('#fixtures')
    view.render()

    AssignmentListItemView.prototype.canManage.restore()
    AssignmentListItemView.prototype.modules.restore()

    view

  module 'AssignmentListItemViewSpec',
    setup: ->
      ENV = window.ENV ||= {}
      ENV.PERMISSIONS = {manage: true}
      window.ENV = ENV

      @model = assignment1()
      @view = createView(@model, canManage: true)
      screenreaderText = =>
        $.trim @view.$('.js-score .screenreader-only').text()
      nonScreenreaderText = =>
        $.trim @view.$('.js-score .non-screenreader').text()

    teardown: ->
      window.ENV = oldENV

  test "initializes child views if can manage", ->
    view = createView(@model, canManage: true)
    ok view.publishIconView
    ok view.dateDueColumnView
    ok view.dateAvailableColumnView
    ok view.moveAssignmentView
    ok view.editAssignmentView

  test "initializes no child views if can't manage", ->
    view = createView(@model, canManage: false)
    ok !view.publishIconView
    ok !view.vddTooltipView
    ok !view.editAssignmentView

  test "upatePublishState toggles ig-published", ->
    view = createView(@model)

    sinon.stub( AssignmentListItemView.prototype, "canManage", -> true )
    sinon.stub( AssignmentListItemView.prototype, "modules", -> )

    ok view.$('.ig-row').hasClass('ig-published')
    @model.set('published', false)
    @model.save()
    ok !view.$('.ig-row').hasClass('ig-published')

    AssignmentListItemView.prototype.canManage.restore()
    AssignmentListItemView.prototype.modules.restore()


  test "delete destroys model", ->
    window.ENV = {context_asset_string: "course_1"}

    view = createView(@model)
    sinon.spy view.model, "destroy"

    view.delete()
    ok view.model.destroy.called
    view.model.destroy.restore()

    ENV.context_asset_string = old_asset_string
  test "updating grades from model change", ->
    @model.set 'grade', 1.5555

    equal screenreaderText(), 'Score: 1.56 out of 2 points', 'sets screenreader text'
    equal nonScreenreaderText(), '1.56/2 pts', 'sets non-screenreader text'

    @model.set 'grade', null
    @model.set 'noSubmission', true

    equal screenreaderText(), 'No submission for this assignment. 2 points possible.',
      'sets screenreader text for null points'
    equal nonScreenreaderText(), '-/2 pts',
      'sets non-screenreader text for null points'

    @model.set 'noSubmission', false
    @model.set 'grade', 0

    equal screenreaderText(), 'Score: 0 out of 2 points',
      'sets screenreader text for 0 points'
    equal nonScreenreaderText(), '0/2 pts',
      'sets non-screenreader text for 0 points'

    @model.set 'notYetGraded', true
    equal screenreaderText(), 'Assignment not yet graded. 2 points possible.',
      'sets correct screenreader text for not yet graded'
    equal nonScreenreaderText(), 'Not Yet Graded/2 pts',
      'sets correct non-screenreader text for not yet graded'

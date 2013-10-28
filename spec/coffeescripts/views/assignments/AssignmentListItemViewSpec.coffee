define [
  'Backbone'
  'compiled/models/Assignment'
  'compiled/views/assignments/AssignmentListItemView'
  'jquery'
  'helpers/jquery.simulate'
  'helpers/fakeENV'
], (Backbone, Assignment, AssignmentListItemView, $) ->
  screenreaderText = null
  nonScreenreaderText = null

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

  assignment_grade_percent = ->
    ac = new AssignmentCollection [buildAssignment(
      "id":2
      "name":"Science Quiz"
      "grading_type": "percent"
    )]
    ac.at(0)


  assignment_grade_pass_fail = ->
    ac = new AssignmentCollection [buildAssignment(
      "id":2
      "name":"Science Quiz"
      "grading_type": "pass_fail"
    )]
    ac.at(0)

  assignment_grade_letter_grade = ->
    ac = new AssignmentCollection [buildAssignment(
      "id":2
      "name":"Science Quiz"
      "grading_type": "letter_grade"
    )]
    ac.at(0)

  assignment_grade_not_graded = ->
    ac = new AssignmentCollection [buildAssignment(
      "id":2
      "name":"Science Quiz"
      "grading_type": "not_graded"
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

    ENV.PERMISSIONS = { manage: options.canManage }

    view = new AssignmentListItemView(model: model)
    view.$el.appendTo $('#fixtures')
    view.render()

    view


  genSetup = (model=assignment1()) ->
    ENV = window.ENV ||= {}
    ENV.PERMISSIONS = {manage: false}
    window.ENV = ENV

    @model = model
    @submission = new Backbone.Model
    @view = createView(@model, canManage: false)
    screenreaderText = =>
      $.trim @view.$('.js-score .screenreader-only').text()
    nonScreenreaderText = =>
      $.trim @view.$('.js-score .non-screenreader').text()


  genTeardown = ->
    ENV.PERMISSIONS = {}
    $('#fixtures').empty()



  module 'AssignmentListItemViewSpec',
    setup: ->
      genSetup.call @

    teardown: ->
      genTeardown.call @

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
    view = createView(@model, canManage: true)

    ok view.$('.ig-row').hasClass('ig-published')
    @model.set('published', false)
    #@model.save()
    ok !view.$('.ig-row').hasClass('ig-published')

  test "delete destroys model", ->
    old_asset_string = ENV.context_asset_string
    ENV.context_asset_string = "course_1"

    view = createView(@model)
    sinon.spy view.model, "destroy"

    view.delete()
    ok view.model.destroy.called
    view.model.destroy.restore()

    ENV.context_asset_string = old_asset_string

  test "updating grades from model change", ->
    @submission.set 'score', 1.5555
    @model.set 'submission', @submission
    @model.trigger 'change:submission'

    equal screenreaderText(), 'Score: 1.56 out of 2 points.', 'sets screenreader text'
    equal nonScreenreaderText(), '1.56/2 pts', 'sets non-screenreader text'

    @model.set 'submission', null
    equal screenreaderText(), 'No submission for this assignment. 2 points possible.',
      'sets screenreader text for null points'
    equal nonScreenreaderText(), '-/2 pts',
      'sets non-screenreader text for null points'

    @submission.set 'score', 0
    @model.set 'submission', @submission

    equal screenreaderText(), 'Score: 0 out of 2 points.',
      'sets screenreader text for 0 points'
    equal nonScreenreaderText(), '0/2 pts',
      'sets non-screenreader text for 0 points'

    @submission.set 'notYetGraded', true
    @model.set 'submission', @submission
    @model.trigger 'change:submission'
    equal screenreaderText(), 'Assignment not yet graded. 2 points possible.',
      'sets correct screenreader text for not yet graded'
    ok nonScreenreaderText().match('-/2 pts')[0],
      'sets correct non-screenreader text for not yet graded'
    ok nonScreenreaderText().match('Not Yet Graded')[0]


  module 'AssignmentListItemViewSpec—alternate grading type: percent',
    setup: ->
      genSetup.call @, assignment_grade_percent()

    teardown: ->
      genTeardown.call @

  test "score and grade outputs", ->
    @submission.set 'score': 1.5555, 'grade': 90
    @model.set 'submission', @submission
    @model.trigger 'change:submission'

    ok screenreaderText().match('Score: 1.56 out of 5 points.')[0], 'sets screenreader score text'
    ok screenreaderText().match('Grade: 90%')[0], 'sets screenreader grade text'
    ok nonScreenreaderText().match('1.56/5 pts')[0], 'sets non-screenreader screen text'
    ok nonScreenreaderText().match('90%')[0], 'sets non-screenreader grade text'


  module 'AssignmentListItemViewSpec—alternate grading type: pass_fail',
    setup: ->
      genSetup.call @, assignment_grade_pass_fail()

    teardown: ->
      genTeardown.call @

  test "score and grade outputs", ->
    @submission.set 'score': 1.5555, 'grade': 'complete'
    @model.set 'submission', @submission
    @model.trigger 'change:submission'

    ok screenreaderText().match('Score: 1.56 out of 5 points.')[0], 'sets screenreader score text'
    ok screenreaderText().match('Grade: Complete')[0], 'sets screenreader grade text'
    ok nonScreenreaderText().match('1.56/5 pts')[0], 'sets non-screenreader score text'
    ok nonScreenreaderText().match('Complete')[0], 'sets non-screenreader grade text'



  module 'AssignmentListItemViewSpec—alternate grading type: letter_grade',
    setup: ->
      genSetup.call @, assignment_grade_letter_grade()

     teardown: ->
      genTeardown.call @

  test "score and grade outputs", ->
    @submission.set 'score': 1.5555, 'grade': 'B'
    @model.set 'submission', @submission
    @model.trigger 'change:submission'

    ok screenreaderText().match('Score: 1.56 out of 5 points.')[0], 'sets screenreader score text'
    ok screenreaderText().match('Grade: B')[0], 'sets screenreader grade text'
    ok nonScreenreaderText().match('1.56/5 pts')[0], 'sets non-screenreader score text'
    ok nonScreenreaderText().match('B')[0], 'sets non-screenreader grade text'



  module 'AssignmentListItemViewSpec—alternate grading type: not_graded',
    setup: ->
      genSetup.call @, assignment_grade_not_graded()

    teardown: ->
      genTeardown.call @

  test "score and grade outputs", ->
    @submission.set 'score': 1.5555, 'grade': 'complete'
    @model.set 'submission', @submission
    @model.trigger 'change:submission'

    equal screenreaderText(), 'This assignment will not be assigned a grade.', 'sets screenreader text'
    equal nonScreenreaderText(), '', 'sets non-screenreader text'



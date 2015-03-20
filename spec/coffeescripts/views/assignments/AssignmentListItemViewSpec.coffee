define [
  'Backbone'
  'compiled/models/Assignment'
  'compiled/models/Submission'
  'compiled/views/assignments/AssignmentListItemView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, Assignment, Submission, AssignmentListItemView, $, fakeENV) ->
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
    options = $.extend {canManage: true, canReadGrades: false}, options

    ENV.PERMISSIONS = {
      manage: options.canManage
      read_grades: options.canReadGrades
    }

    view = new AssignmentListItemView(model: model)
    view.$el.appendTo $('#fixtures')
    view.render()

    view

  genModules = (count) ->
    if count == 1
      ["First"]
    else
      ["First", "Second"]

  genSetup = (model=assignment1()) ->
    fakeENV.setup(PERMISSIONS: {manage: false})

    @model = model
    @submission = new Submission
    @view = createView(@model, canManage: false)
    screenreaderText = =>
      $.trim @view.$('.js-score .screenreader-only').text()
    nonScreenreaderText = =>
      $.trim @view.$('.js-score .non-screenreader').text()

  genTeardown = ->
    fakeENV.teardown()
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

  test 'asks for confirmation before deleting an assignment', ->
    view = createView(@model)

    group_stub = sinon.stub(view, 'visibleAssignments', -> [])
    confirm_stub = sinon.stub(window, "confirm", -> true )
    delete_spy = sinon.spy view, "delete"

    view.$("#assignment_#{@model.id} .delete_assignment").click()

    ok confirm_stub.called
    ok delete_spy.called

    confirm_stub.restore()
    delete_spy.restore()
    group_stub.restore()

  test "delete destroys model", ->
    old_asset_string = ENV.context_asset_string
    ENV.context_asset_string = "course_1"

    view = createView(@model)
    sinon.spy view.model, "destroy"

    view.delete()
    ok view.model.destroy.called
    view.model.destroy.restore()

    ENV.context_asset_string = old_asset_string

  test "show score if score is set", ->
    @submission.set 'score': 1.5555, 'grade': '1.5555'
    @model.set 'submission', @submission
    @model.trigger 'change:submission'

    equal screenreaderText(), 'Score: 1.56 out of 2 points.', 'sets screenreader text'
    equal nonScreenreaderText(), '1.56/2 pts', 'sets non-screenreader text'

  test 'do not show score if viewing as non-student', ->
    old_user_roles = ENV.current_user_roles
    ENV.current_user_roles = ["user"]

    view = createView(@model, canManage: false)
    str = view.$(".js-score:eq(0) .non-screenreader").html()
    ok str.search("2 pts") != -1

    ENV.current_user_roles = old_user_roles

  test "show no submission if none exists", ->
    @model.set 'submission': null
    equal screenreaderText(), 'No submission for this assignment. 2 points possible.',
      'sets screenreader text for null points'
    equal nonScreenreaderText(), '-/2 pts',
      'sets non-screenreader text for null points'

  test "show score if 0 correctly", ->
    @submission.set 'score': 0, 'grade': '0'
    @model.set 'submission', @submission

    equal screenreaderText(), 'Score: 0 out of 2 points.',
      'sets screenreader text for 0 points'
    equal nonScreenreaderText(), '0/2 pts',
      'sets non-screenreader text for 0 points'

  test "show no submission if submission object with no submission type", ->
    @model.set 'submission', @submission
    @model.trigger 'change:submission'
    equal screenreaderText(), 'No submission for this assignment. 2 points possible.',
      'sets correct screenreader text for not yet graded'
    equal nonScreenreaderText(), '-/2 pts',
      'sets correct non-screenreader text for not yet graded'

  test "show not yet graded if submission type but no grade", ->
    @submission.set 'submission_type': 'online', 'notYetGraded': true
    @model.set 'submission', @submission
    @model.trigger 'change:submission'
    equal screenreaderText(), 'Assignment not yet graded. 2 points possible.',
      'sets correct screenreader text for not yet graded'
    ok nonScreenreaderText().match('-/2 pts')[0],
      'sets correct non-screenreader text for not yet graded'
    ok nonScreenreaderText().match('Not Yet Graded')[0]

  test "focus returns to cog after dismissing dialog", ->
    view = createView(@model, canManage: true)
    trigger = view.$("#assign_#{@model.id}_manage_link")
    ok(trigger.length, 'there is an a node with the correct id')
    #show menu
    trigger.click()

    view.$("#assignment_#{@model.id}_settings_edit_item").click()
    view.editAssignmentView.close()

    equal document.activeElement, trigger.get(0)

  test "assignment cannot be deleted if frozen", ->
    @model.set('frozen', true)
    view = createView(@model)
    ok !view.$("#assignment_#{@model.id} a.delete_assignment").length

  test "allows publishing", ->
    #setup fake server
    @server = sinon.fakeServer.create()
    @server.respondWith "PUT", "/api/v1/users/1/assignments/1", [
      200,
      { "Content-Type": "application/json" },
      JSON.stringify("")
    ]
    @model.set 'published', false
    view = createView(@model)

    view.$("#assignment_#{@model.id} .publish-icon").click()
    @server.respond()

    equal @model.get('published'), true
    @server.restore()

  test "correctly displays module's name", ->
    mods = genModules(1)
    @model.set('modules', mods)
    view = createView(@model)
    ok view.$(".modules").text().search("#{mods[0]} Module") != -1

  test "correctly display's multiple modules", ->
    mods = genModules(2)
    @model.set('modules', mods)
    view = createView(@model)
    ok view.$(".modules").text().search("Multiple Modules") != -1
    ok view.$("#module_tooltip_#{@model.id}").text().search("#{mods[0]}") != -1
    ok view.$("#module_tooltip_#{@model.id}").text().search("#{mods[1]}") != -1

  test 'render score template with permission', ->
    spy = sinon.spy(AssignmentListItemView.prototype, 'updateScore')
    createView(@model, canManage: false, canReadGrades: true)
    ok spy.called
    AssignmentListItemView.prototype.updateScore.restore()

  test 'does not render score template without permission', ->
    spy = sinon.spy(AssignmentListItemView.prototype, 'updateScore')
    createView(@model, canManage: false, canReadGrades: false)
    equal spy.callCount, 0
    AssignmentListItemView.prototype.updateScore.restore()

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



define [
  'Backbone'
  'compiled/models/Assignment'
  'compiled/models/Submission'
  'compiled/views/assignments/AssignmentListItemView'
  'jquery'
  'timezone'
  'vendor/timezone/America/Juneau'
  'vendor/timezone/fr_FR'
  'helpers/I18nStubber'
  'helpers/fakeENV'
  'jsx/shared/conditional_release/CyoeHelper'
  'helpers/jquery.simulate'
], (Backbone, Assignment, Submission, AssignmentListItemView, $, tz, juneau, french, I18nStubber, fakeENV, CyoeHelper) ->
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

    buildAssignment
      "id":1
      "name":"History Quiz"
      "description":"test"
      "due_at":"2013-08-21T23:59:00-06:00"
      "points_possible":2
      "position":1
      "all_dates":[date1, date2]

  assignment2 = ->
    buildAssignment
      "id":3
      "name":"Math Quiz"
      "due_at":"2013-08-23T23:59:00-06:00"
      "points_possible":10
      "position":2

  assignment3 = ->
    buildAssignment
      "id":2
      "name":"Science Quiz"
      "points_possible":5
      "position":3

  assignment_grade_percent = ->
    buildAssignment
      "id":2
      "name":"Science Quiz"
      "grading_type": "percent"

  assignment_grade_pass_fail = ->
    buildAssignment
      "id":2
      "name":"Science Quiz"
      "grading_type": "pass_fail"

  assignment_grade_letter_grade = ->
    buildAssignment
      "id":2
      "name":"Science Quiz"
      "grading_type": "letter_grade"

  assignment_grade_not_graded = ->
    buildAssignment
      "id":2
      "name":"Science Quiz"
      "grading_type": "not_graded"

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

    ac = new AssignmentCollection [base]
    ac.at(0)

  createView = (model, options) ->
    options = $.extend {canManage: true, canReadGrades: false}, options

    ENV.PERMISSIONS = {
      manage: options.canManage
      read_grades: options.canReadGrades
    }

    ENV.POST_TO_SIS = options.post_to_sis

    view = new AssignmentListItemView(model: model, userIsAdmin: options.userIsAdmin)
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
      @snapshot = tz.snapshot()
      I18nStubber.pushFrame()

    teardown: ->
      genTeardown.call @
      tz.restore(@snapshot)
      I18nStubber.popFrame()

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

  test "initializes sis toggle if post to sis enabled", ->
    view = createView(@model, canManage: true, post_to_sis: true)
    ok view.sisButtonView

  test "does not initialize sis toggle if post to sis disabled", ->
    view = createView(@model, canManage: true, post_to_sis: false)
    ok !view.sisButtonView

  test "does not initialize sis toggle if assignment is not graded", ->
    @model.set('submission_types', ["not_graded"])
    view = createView(@model, canManage: true, post_to_sis: true)
    ok !view.sisButtonView

  test "does not initialize sis toggle if post to sis disabled but can't manage", ->
    view = createView(@model, canManage: false, post_to_sis: false)
    ok !view.sisButtonView

  test "does not initialize sis toggle if sis enabled but can't manage", ->
    view = createView(@model, canManage: false, post_to_sis: true)
    ok !view.sisButtonView

  test "upatePublishState toggles ig-published", ->
    view = createView(@model, canManage: true)

    ok view.$('.ig-row').hasClass('ig-published')
    @model.set('published', false)
    ok !view.$('.ig-row').hasClass('ig-published')

  test 'asks for confirmation before deleting an assignment', ->
    view = createView(@model)

    @stub(view, 'visibleAssignments', -> [])
    @stub(window, "confirm", -> true )
    @spy view, "delete"

    view.$("#assignment_#{@model.id} .delete_assignment").click()

    ok window.confirm.called
    ok view.delete.called

  test 'does not attempt to delete an assignment due in a closed grading period', ->
    @model.set('has_due_date_in_closed_grading_period', true)
    view = createView(@model)

    @stub(window, "confirm", -> true )
    @spy view, "delete"

    view.$("#assignment_#{@model.id} .delete_assignment").click()

    ok window.confirm.notCalled
    ok view.delete.notCalled

  test "delete destroys model", ->
    old_asset_string = ENV.context_asset_string
    ENV.context_asset_string = "course_1"

    view = createView(@model)
    @spy view.model, "destroy"

    view.delete()
    ok view.model.destroy.called

    ENV.context_asset_string = old_asset_string

  test "delete calls screenreader message", ->
    old_asset_string = ENV.context_asset_string
    ENV.context_asset_string = "course_1"
    server = sinon.fakeServer.create()
    server.respondWith('DELETE', '/api/v1/courses/1/assignments/1',
      [200, { 'Content-Type': 'application/json' }, JSON.stringify({
      "description":"",
      "due_at":null,
      "grade_group_students_individually":false,
      "grading_standard_id":null,
      "grading_type":"points",
      "group_category_id":null,
      "id":"1",
      "unpublishable":true,
      "only_visible_to_overrides":false,
      "locked_for_user":false})])

    view = createView(@model)
    view.delete()
    @spy($, 'screenReaderFlashMessage')
    server.respond()
    equal $.screenReaderFlashMessage.callCount, 1
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
    trigger.click()

    view.$("#assignment_#{@model.id}_settings_edit_item").click()
    view.editAssignmentView.close()

    equal document.activeElement, trigger.get(0)

  test "disallows deleting frozen assignments", ->
    @model.set('frozen', true)
    view = createView(@model)
    ok view.$("#assignment_#{@model.id} a.delete_assignment.disabled").length

  test "disallows deleting assignments due in closed grading periods", ->
    @model.set('has_due_date_in_closed_grading_period', true)
    view = createView(@model)
    ok view.$("#assignment_#{@model.id} a.delete_assignment.disabled").length

  test "allows deleting non-frozen assignments not due in closed grading periods", ->
    @model.set('frozen', false)
    @model.set('has_due_date_in_closed_grading_period', false)
    view = createView(@model)
    ok view.$("#assignment_#{@model.id} a.delete_assignment:not(.disabled)").length

  test "allows deleting frozen assignments for admins", ->
    @model.set('frozen', true)
    view = createView(@model, userIsAdmin: true)
    ok view.$("#assignment_#{@model.id} a.delete_assignment:not(.disabled)").length

  test "allows deleting assignments due in closed grading periods for admins", ->
    @model.set('has_assignment_due_in_closed_grading_period', true)
    view = createView(@model, userIsAdmin: true)
    ok view.$("#assignment_#{@model.id} a.delete_assignment:not(.disabled)").length

  test "allows publishing", ->
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
    spy = @spy(AssignmentListItemView.prototype, 'updateScore')
    createView(@model, canManage: false, canReadGrades: true)
    ok spy.called

  test 'does not render score template without permission', ->
    spy = @spy(AssignmentListItemView.prototype, 'updateScore')
    createView(@model, canManage: false, canReadGrades: false)
    equal spy.callCount, 0

  test "renders lockAt/unlockAt with locale-appropriate format string", ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR',
      'date.formats.short': '%-d %b'
      'date.abbr_month_names.8': 'août'
    model = buildAssignment
      id: 1
      lock_at: "2113-08-28T04:00:00Z"
      all_dates: [
        { lock_at: "2113-08-28T04:00:00Z", title: "Summer Session" }
        { unlock_at: "2113-08-28T04:00:00Z", title: "Winter Session" }]

    view = createView(model, canManage: true)
    $dds = view.dateAvailableColumnView.$("#vdd_tooltip_#{@model.id}_lock div")
    equal $("span", $dds.first()).last().text().trim(), '28 août'
    equal $("span", $dds.last()).last().text().trim(), '28 août'

  test "renders lockAt/unlockAt in appropriate time zone", ->
    tz.changeZone(juneau, 'America/Juneau')
    I18nStubber.stub 'en',
      'date.formats.short': '%b %-d'
      'date.abbr_month_names.8': 'Aug'

    model = buildAssignment
      id: 1
      lock_at: "2113-08-28T04:00:00Z"
      all_dates: [
        { lock_at: "2113-08-28T04:00:00Z", title: "Summer Session" }
        { unlock_at: "2113-08-28T04:00:00Z", title: "Winter Session" }]

    view = createView(model, canManage: true)
    $dds = view.dateAvailableColumnView.$("#vdd_tooltip_#{@model.id}_lock div")
    equal $("span", $dds.first()).last().text().trim(), 'Aug 27'
    equal $("span", $dds.last()).last().text().trim(), 'Aug 27'

  test 'renders lockAt/unlockAt for multiple due dates', ->
    now = new Date()
    model = buildAssignment
      id: 1
      all_dates: [
        { due_at: new Date().toISOString() }
        { due_at: new Date().toISOString() }
      ]
    view = createView(model)
    json = view.toJSON()
    equal json.showAvailability, true

  test 'renders lockAt/unlockAt when locked', ->
    future = new Date()
    future.setDate(future.getDate() + 10)
    model = buildAssignment
      id: 1
      unlock_at: future.toISOString()
    view = createView(model)
    json = view.toJSON()
    equal json.showAvailability, true

  test 'renders lockAt/unlockAt when locking in future', ->
    past = new Date()
    past.setDate(past.getDate() - 10)
    future = new Date()
    future.setDate(future.getDate() + 10)
    model = buildAssignment
      id: 1
      unlock_at: past,
      lock_at: future.toISOString()
    view = createView(model)
    json = view.toJSON()
    equal json.showAvailability, true

  test 'does not render lockAt/unlockAt when not locking in future', ->
    past = new Date()
    past.setDate(past.getDate() - 10)
    model = buildAssignment
      id: 1
      unlock_at: past.toISOString()
    view = createView(model)
    json = view.toJSON()
    equal json.showAvailability, false

  test "renders due date column with locale-appropriate format string", ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR',
      'date.formats.short': '%-d %b'
      'date.abbr_month_names.8': 'août'
    view = createView(@model, canManage: true)
    equal view.dateDueColumnView.$("#vdd_tooltip_#{@model.id}_due div dd").first().text().trim(), '29 août'

  test "renders due date column in appropriate time zone", ->
    tz.changeZone(juneau, 'America/Juneau')
    I18nStubber.stub 'en',
      'date.formats.short': '%b %-d'
      'date.abbr_month_names.8': 'Aug'
    view = createView(@model, canManage: true)
    equal view.dateDueColumnView.$("#vdd_tooltip_#{@model.id}_due div dd").first().text().trim(), 'Aug 28'

  test 'can move when userIsAdmin is true', ->
    view = createView(@model, userIsAdmin: true, canManage: false)
    json = view.toJSON()
    ok json.canMove
    notOk view.className().includes('sort-disabled')

  test 'can move when canManage is true and the model can be deleted', ->
    @stub(@model, 'canDelete').returns(true)
    view = createView(@model, userIsAdmin: false, canManage: true)
    json = view.toJSON()
    ok json.canMove
    notOk view.className().includes('sort-disabled')

  test 'cannot move when canManage is true but the model cannot be deleted', ->
    @stub(@model, 'canDelete').returns(false)
    view = createView(@model, userIsAdmin: false, canManage: true)
    json = view.toJSON()
    notOk json.canMove
    ok view.className().includes('sort-disabled')

  test 'cannot move when canManage is false but the model can be deleted', ->
    @stub(@model, 'canDelete').returns(true)
    view = createView(@model, userIsAdmin: false, canManage: false)
    json = view.toJSON()
    notOk json.canMove
    ok view.className().includes('sort-disabled')

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

  test "excused score and grade outputs", ->
    @submission.set 'excused': true
    @model.set 'submission', @submission
    @model.trigger 'change:submission'

    ok screenreaderText().match('This assignment has been excused.')
    ok nonScreenreaderText().match('Excused')

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

  module 'AssignListItemViewSpec - mastery paths menu option',
    setup: ->
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true

  test 'does not render for assignment if cyoe off', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    model = buildAssignment
      id: 1
      title: 'Foo'
      can_update: true
      submission_types: ['online_text_entry']
    view = createView(model)
    equal view.$('.ig-admin .al-options .icon-mastery-path').length, 0

  test 'renders for assignment if cyoe on', ->
    model = buildAssignment
      id: 1
      title: 'Foo'
      can_update: true
      submission_types: ['online_text_entry']
    view = createView(model)
    equal view.$('.ig-admin .al-options .icon-mastery-path').length, 1

  test 'does not render for ungraded assignment if cyoe on', ->
    model = buildAssignment
      id: 1
      title: 'Foo'
      can_update: true
      submission_types: ['not_graded']
    view = createView(model)
    equal view.$('.ig-admin .al-options .icon-mastery-path').length, 0

  test 'renders for assignment quiz if cyoe on', ->
    model = buildAssignment
      id: 1
      title: 'Foo'
      can_update: true
      is_quiz_assignment: true
      submission_types: ['online_quiz']
    view = createView(model)
    equal view.$('.ig-admin .al-options .icon-mastery-path').length, 1

  test 'does not render for non-assignment quiz if cyoe on', ->
    model = buildAssignment
      id: 1
      title: 'Foo'
      can_update: true
      is_quiz_assignment: false
      submission_types: ['online_quiz']
    view = createView(model)
    equal view.$('.icon-mastery-path').length, 0

  test 'renders for graded discussion if cyoe on', ->
    model = buildAssignment
      id: 1
      title: 'Foo'
      can_update: true
      submission_types: ['discussion_topic']
    view = createView(model)
    equal view.$('.ig-admin .al-options .icon-mastery-path').length, 1

  test 'does not render for graded page if cyoe on', ->
    model = buildAssignment
      id: 1
      title: 'Foo'
      can_update: true
      submission_types: ['wiki_page']
    view = createView(model)
    equal view.$('.ig-admin .al-options .icon-mastery-path').length, 0

  module 'AssignListItemViewSpec - mastery paths link',
    setup: ->
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = {
        active_rules: [{
          trigger_assignment: '1',
          scoring_ranges: [
            {
              assignment_sets: [
                { assignments: [{ assignment_id: '2' }] },
              ],
            },
          ],
        }],
      }
      CyoeHelper.reloadEnv()

  test 'does not render for assignment if cyoe off', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    model = buildAssignment
      id: '1'
      title: 'Foo'
      can_update: true
      submission_types: ['online_text_entry']
    view = createView(model)
    equal view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0

  test 'does not render for assignment if assignment does not have a rule', ->
    model = buildAssignment
      id: '2'
      title: 'Foo'
      can_update: true
      submission_types: ['online_text_entry']
    view = createView(model)
    equal view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 0

  test 'renders for assignment if assignment has a rule', ->
    model = buildAssignment
      id: '1'
      title: 'Foo'
      can_update: true
      submission_types: ['online_text_entry']
    view = createView(model)
    equal view.$('.ig-admin > a[href$="#mastery-paths-editor"]').length, 1

  module 'AssignListItemViewSpec - mastery paths icon',
    setup: ->
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = {
        active_rules: [{
          trigger_assignment: '1',
          scoring_ranges: [
            {
              assignment_sets: [
                { assignments: [{ assignment_id: '2' }] },
              ],
            },
          ],
        }],
      }
      CyoeHelper.reloadEnv()

  test 'does not render for assignment if cyoe off', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    model = buildAssignment
      id: '2'
      title: 'Foo'
      can_update: true
      submission_types: ['online_text_entry']
    view = createView(model)
    equal view.$('.mastery-path-icon').length, 0

  test 'does not render for assignment if assignment is not released by a rule', ->
    model = buildAssignment
      id: '1'
      title: 'Foo'
      can_update: true
      submission_types: ['online_text_entry']
    view = createView(model)
    equal view.$('.mastery-path-icon').length, 0

  test 'renders for assignment if assignment is released by a rule', ->
    model = buildAssignment
      id: '2'
      title: 'Foo'
      can_update: true
      submission_types: ['online_text_entry']
    view = createView(model)
    equal view.$('.mastery-path-icon').length, 1

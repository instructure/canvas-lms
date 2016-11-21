define [
  'underscore'
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/models/Course'
  'compiled/views/assignments/CreateGroupView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (_, Backbone, AssignmentGroupCollection, AssignmentGroup, Assignment, Course, CreateGroupView, $, fakeENV) ->

  group = (opts = {}) ->
    new AssignmentGroup $.extend({
      name: 'something cool'
      assignments: [new Assignment, new Assignment]
    }, opts)

  assignmentGroups = ->
    new AssignmentGroupCollection([group(), group()])

  createView = (opts = {})->
    groups = opts.assignmentGroups or assignmentGroups()
    args =
      course: opts.course or new Course(apply_assignment_group_weights: true)
      assignmentGroups: groups
      assignmentGroup:
        opts.group or (groups.first() unless opts.newGroup?)
      userIsAdmin: opts.userIsAdmin

    new CreateGroupView(args)

  module 'CreateGroupView',
    setup: ->
      fakeENV.setup()
    teardown: ->
      fakeENV.teardown()
      $("form[id^=ui-id-]").remove()

  test 'hides drop options for no assignments', ->
    view = createView()
    view.render()
    ok view.$('[name="rules[drop_lowest]"]').length
    ok view.$('[name="rules[drop_highest]"]').length

    view.assignmentGroup.get('assignments').reset []
    view.render()
    equal view.$('[name="rules[drop_lowest]"]').length, 0
    equal view.$('[name="rules[drop_highest]"]').length, 0

  test 'it should not add errors when never_drop rules are added', ->
    view = createView()
    data =
      name: "Assignments"
      rules:
        never_drop: ["1854", "352", "234563"]

    errors = view.validateFormData(data)
    ok _.isEmpty(errors)

  test 'it should create a new assignment group', ->
    @stub(CreateGroupView.prototype, 'close', -> )

    view = createView(newGroup: true)
    view.render()
    view.onSaveSuccess()
    equal view.assignmentGroups.size(), 3

  test 'it should edit an existing assignment group', ->
    view = createView()
    save_spy = @stub(view.model, "save", -> $.Deferred().resolve())
    view.render()
    view.open()
    #the selector uses 'new' for id because this model hasn't been saved yet
    view.$("#ag_new_name").val("IchangedIt")
    view.$("#ag_new_drop_lowest").val("1")
    view.$("#ag_new_drop_highest").val("1")
    view.$(".create_group").click()

    formData = view.getFormData()
    equal formData["name"], "IchangedIt"
    equal formData["rules"]["drop_lowest"], 1
    equal formData["rules"]["drop_highest"], 1
    ok save_spy.called

  test 'it should not save drop rules when none are given', ->
    view = createView()
    save_spy = @stub(view.model, "save", -> $.Deferred().resolve())
    view.render()
    view.open()
    view.$("#ag_new_drop_lowest").val("")
    equal view.$("#ag_new_drop_highest").val(), "0"
    view.$("#ag_new_name").val("IchangedIt")
    view.$(".create_group").click()

    formData = view.getFormData()
    equal formData["name"], "IchangedIt"
    equal _.keys(formData["rules"]).length, 0
    ok save_spy.called

  test 'it should only allow positive numbers for drop rules', ->
    view = createView()
    data =
      name: "Assignments"
      rules:
        drop_lowest: "tree"
        drop_highest: -1
        never_drop: ['1', '2', '3']

    errors = view.validateFormData(data)
    ok errors
    equal _.keys(errors).length, 2

  test 'it should only allow less than the number of assignments for drop rules', ->
    view = createView()
    assignments = view.assignmentGroup.get('assignments')

    data =
      name: "Assignments"
      rules:
        drop_highest: 5

    errors = view.validateFormData(data)
    ok errors
    equal _.keys(errors).length, 1

  test 'it should not allow assignment groups with no name', ->
    view = createView()
    assignments = view.assignmentGroup.get('assignments')

    data =
      name: ""

    errors = view.validateFormData(data)
    ok errors
    equal _.keys(errors).length, 1

  test 'it should trigger a render event on save success when editing', ->
    triggerSpy = @spy(AssignmentGroupCollection::, 'trigger')
    view = createView()
    view.onSaveSuccess()
    ok triggerSpy.calledWith 'render'

  test 'it should call render on save success if adding an assignmentGroup', ->
    view = createView(newGroup: true)
    @stub(view, 'render')
    view.onSaveSuccess()
    equal view.render.callCount, 1

  test 'it shows a success message', ->
    @stub(CreateGroupView.prototype, 'close', -> )
    @spy($, 'flashMessage')
    clock = sinon.useFakeTimers()

    view = createView(newGroup: true)
    view.render()
    view.onSaveSuccess()
    clock.tick(101)

    equal $.flashMessage.callCount, 1
    clock.restore()

  test 'does not render group weight input when the course is not using weights', ->
    groups = new AssignmentGroupCollection([group(), group()])
    course = new Course(apply_assignment_group_weights: false)
    view = createView(assignmentGroups: groups, course: course)
    view.render()
    notOk view.showWeight()
    notOk view.$('[name="group_weight"]').length

  test 'disables group weight input when an assignment is due in a closed grading period', ->
    ENV.MULTIPLE_GRADING_PERIODS_ENABLED = true
    closed_group = group(has_assignment_due_in_closed_grading_period: true)
    groups = new AssignmentGroupCollection([group(), closed_group])
    view = createView(group: closed_group, assignmentGroups: groups)
    view.render()
    notOk view.canChangeWeighting()
    ok view.$('[name="group_weight"]').attr('readonly')

  test 'does not disable group weight input when userIsAdmin is true', ->
    ENV.MULTIPLE_GRADING_PERIODS_ENABLED = true
    closed_group = group(has_assignment_due_in_closed_grading_period: true)
    groups = new AssignmentGroupCollection([group(), closed_group])
    view = createView(group: closed_group, assignmentGroups: groups, userIsAdmin: true)
    view.render()
    ok view.canChangeWeighting()
    notOk view.$('[name="group_weight"]').attr('readonly')

  test 'disables drop rule inputs when an assignment is due in a closed grading period', ->
    ENV.MULTIPLE_GRADING_PERIODS_ENABLED = true
    closed_group = group(has_assignment_due_in_closed_grading_period: true)
    groups = new AssignmentGroupCollection([group(), closed_group])
    view = createView(group: closed_group, assignmentGroups: groups)
    view.render()
    ok view.$('[name="rules[drop_lowest]"]').attr('readonly')
    ok view.$('[name="rules[drop_highest]"]').attr('readonly')

  test 'does not disable drop rule inputs when userIsAdmin is true', ->
    ENV.MULTIPLE_GRADING_PERIODS_ENABLED = true
    closed_group = group(has_assignment_due_in_closed_grading_period: true)
    groups = new AssignmentGroupCollection([group(), closed_group])
    view = createView(group: closed_group, assignmentGroups: groups, userIsAdmin: true)
    view.render()
    notOk view.$('[name="rules[drop_lowest]"]').attr('readonly')
    notOk view.$('[name="rules[drop_highest]"]').attr('readonly')

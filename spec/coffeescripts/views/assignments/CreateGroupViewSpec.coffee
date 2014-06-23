define [
  'underscore'
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/views/assignments/CreateGroupView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (_, Backbone, AssignmentGroupCollection, AssignmentGroup, Assignment, CreateGroupView, $, fakeENV) ->

  group = ->
    new AssignmentGroup
      name: 'something cool'
      assignments: [new Assignment, new Assignment]

  assignmentGroups = ->
    @groups = new AssignmentGroupCollection([group(), group()])

  createView = (hasAssignmentGroup=true)->
    args =
      assignmentGroups: assignmentGroups()
      assignmentGroup: @groups.first() if hasAssignmentGroup

    new CreateGroupView(args)

  module 'CreateGroupView',
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

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
    close_stub = sinon.stub(CreateGroupView.prototype, 'close', -> )

    view = createView(false)
    view.render()
    view.onSaveSuccess()
    equal view.assignmentGroups.size(), 3

    close_stub.restore()

  test 'it should edit an existing assignment group', ->
    view = createView()
    save_spy = sinon.spy(view.model, "save")
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
    save_spy.restore()

  test 'it should not save drop rules when none are given', ->
    view = createView()
    save_spy = sinon.spy(view.model, "save")
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
    save_spy.restore()

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
    triggerSpy = sinon.spy(AssignmentGroupCollection::, 'trigger')
    view = createView()
    view.onSaveSuccess()
    ok triggerSpy.calledWith 'render'
    triggerSpy.restore()

  test 'it should call render on save success if adding an assignmentGroup', ->
    view = createView(false)
    renderStub = sinon.stub(view, 'render')
    calls = renderStub.callCount
    view.onSaveSuccess()
    equal renderStub.callCount, calls + 1

define [
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/Course'
  'compiled/models/AssignmentGroup'
  'compiled/views/assignments/AssignmentSettingsView'
  'compiled/views/assignments/AssignmentGroupWeightsView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, AssignmentGroupCollection, Course, AssignmentGroup, AssignmentSettingsView, AssignmentGroupWeightsView, $, fakeENV) ->

  group = ->
    new AssignmentGroup {group_weight: 50}

  assignmentGroups = ->
    @groups = new AssignmentGroupCollection([group(), group()])

  createView = (apply_assignment_group_weights) ->
    @course = new Course
      apply_assignment_group_weights: apply_assignment_group_weights
    @course.urlRoot = "/courses/1" #without this it keeps throwing an error
    view = new AssignmentSettingsView
      model: @course
      assignmentGroups: assignmentGroups()
      weightsView: AssignmentGroupWeightsView
    view.open()
    view

  module 'AssignmentSettingsView',
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

  test 'it should set the checkbox to the right value on open', ->
    view = createView(true)
    ok view.$('#apply_assignment_group_weights').prop('checked')
    view.remove()

    view = createView(false)
    ok !view.$('#apply_assignment_group_weights').prop('checked')
    view.remove()

  test 'it should show the weights table when checked', ->
    view = createView(true)
    ok view.$('#ag_weights_wrapper').is(":visible")
    view.remove()

  test 'it should hide the weights table when clicked', ->
    view = createView(true)
    ok view.$('#ag_weights_wrapper').is(":visible")
    view.$('#apply_assignment_group_weights').click()
    ok view.$('#ag_weights_wrapper').not(":visible")
    view.remove()

  test 'it should change the apply_assignment_group_weights flag', ->
    view = createView(true)
    view.$('#apply_assignment_group_weights').click()
    attributes = view.getFormData()
    ok !!attributes.apply_assignment_group_weights
    view.remove()

  test 'group weights should be saved', ->
    view = createView(true)
    view.$(".ag-weights-tr:eq(0) .group_weight_value").val("20")
    view.$(".ag-weights-tr:eq(1) .group_weight_value").val("80")

    view.$("#update-assignment-settings").click()
    equal view.assignmentGroups.first().get('group_weight'), 20
    equal view.assignmentGroups.last().get('group_weight'), 80
    view.remove()


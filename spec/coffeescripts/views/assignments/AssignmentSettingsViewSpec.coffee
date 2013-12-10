define [
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/Course'
  'compiled/models/AssignmentGroup'
  'compiled/views/assignments/AssignmentSettingsView'
  'compiled/views/assignments/AssignmentGroupWeightsView'
  'jquery'
  'helpers/jquery.simulate'
  'helpers/fakeENV'
], (Backbone, AssignmentGroupCollection, Course, AssignmentGroup, AssignmentSettingsView, AssignmentGroupWeightsView, $) ->

  group = ->
    new AssignmentGroup {group_weight: 50}

  assignmentGroups = ->
    @groups = new AssignmentGroupCollection([group(), group()])

  createView = (apply_assignment_group_weights) ->
    @course = new Course {apply_assignment_group_weights: apply_assignment_group_weights}
    view = new AssignmentSettingsView
      model: @course
      assignmentGroups: assignmentGroups()
      weightsView: AssignmentGroupWeightsView
    view.$el.appendTo $('#fixtures')
    view.render()

  module 'AssignmentSettingsView'

  test 'it should set the checkbox to the right value on open', ->
    view = createView(true)
    ok view.$('#apply_assignment_group_weights').prop('checked')

    view = createView(false)
    ok !view.$('#apply_assignment_group_weights').prop('checked')

  test 'it should show the weights table when checked', ->
    view = createView(true)
    ok !!view.$('#ag_weights_wrapper:visible').length

  test 'it should hide the weights table when clicked', ->
    view = createView(true)
    view.$('#apply_assignment_group_weights').click()
    ok !view.$('#ag_weights_wrapper:visible').length

  test 'it should change the apply_assignment_group_weights flag', ->
    view = createView(true)
    view.$('#apply_assignment_group_weights').click()

    attributes = view.getFormData()
    ok !!attributes.apply_assignment_group_weights

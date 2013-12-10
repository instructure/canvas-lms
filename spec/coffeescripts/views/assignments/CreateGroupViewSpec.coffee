define [
  'underscore'
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/views/assignments/CreateGroupView'
  'jquery'
  'helpers/jquery.simulate'
  'helpers/fakeENV'
], (_, Backbone, AssignmentGroupCollection, AssignmentGroup, Assignment, CreateGroupView, $) ->

  group = ->
    new AssignmentGroup
      assignments: [new Assignment, new Assignment]

  assignmentGroups = ->
    @groups = new AssignmentGroupCollection([group(), group()])

  createView = ->
    view = new CreateGroupView
      assignmentGroups: assignmentGroups()
      assignmentGroup: @groups.first()

  module 'CreateGroupView'

  test 'it should only allow positive numbers for drop rules', ->
    view = createView()
    data =
      rules:
        drop_lowest: "tree"
        drop_highest: -1

    errors = view.validateFormData(data)
    ok errors
    equal _.keys(errors).length, 2


  test 'it should only allow less than the number of assignments for drop rules', ->
    view = createView()
    assignments = view.assignmentGroup.get('assignments')

    data =
      rules:
        drop_highest: 5

    errors = view.validateFormData(data)
    ok errors
    equal _.keys(errors).length, 1

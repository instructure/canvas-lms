define [
  'underscore'
  'Backbone'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/collections/AssignmentCollection'
  'compiled/models/AssignmentGroup'
  'compiled/models/Assignment'
  'compiled/views/assignments/DeleteGroupView'
  'jquery'
  'helpers/jquery.simulate'
  'helpers/fakeENV'
], (_, Backbone, AssignmentGroupCollection, AssignmentCollection, AssignmentGroup, Assignment, DeleteGroupView, $) ->

  group = (assignments=true, id) ->
    new AssignmentGroup
      id: id
      name: "something cool #{id}"
      assignments: if assignments then [new Assignment, new Assignment] else []

  assignmentGroups = (assignments=true, multiple=true) ->
    groups = if multiple then [group(assignments, 1), group(assignments, 2)] else [group(assignments, 1)]
    new AssignmentGroupCollection(groups)

  createView = (assignments=true, multiple=true) ->
    ags = assignmentGroups(assignments, multiple)
    ag_group = ags.first()

    new DeleteGroupView
      model: ag_group

  module 'DeleteGroupView'

  test 'it should delete a group without assignments', ->
    confirm_stub = sinon.stub(window, "confirm", -> true )
    view = createView(false, true)
    destroy_stub = sinon.stub(view, "destroyModel", -> )
    view.render()
    view.open()

    ok confirm_stub.called
    ok destroy_stub.called
    confirm_stub.restore()
    destroy_stub.restore()

  test 'assignment and ag counts should be correct', ->
    view = createView(true, true)
    view.render()
    view.open()

    equal view.$('.assignment_count:visible').text(), "2"
    equal view.$('.group_select option').length, 2
    view.close()

  test 'assignment and ag counts should update', ->
    view = createView(true, true)
    view.render()
    view.open()
    view.close()

    view.model.get('assignments').add(new Assignment)
    view.model.collection.add(new AssignmentGroup)

    view.open()
    equal view.$('.assignment_count:visible').text(), "3"
    equal view.$('.group_select:visible option').length, 3
    view.close()

  test 'it should delete a group with assignments', ->
    destroy_stub = sinon.stub(DeleteGroupView.prototype, "destroy", -> )
    view = createView(true, true)
    view.render()
    view.open()

    view.$(".delete_group").click()

    ok destroy_stub.called
    destroy_stub.restore()
    view.close()

  test 'it should not delete the last assignment group', ->
    alert_stub = sinon.stub(window, "alert", -> true )
    view = createView(true, false)
    destroy_spy = sinon.spy(view, "destroyModel")
    view.render()
    view.open()

    ok alert_stub.called
    ok !destroy_spy.called
    alert_stub.restore()
    destroy_spy.restore()
    view.close()
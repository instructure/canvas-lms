define [
  'underscore'
  'Backbone'
  'compiled/collections/NeverDropCollection'
], (_, Backbone, NeverDropCollection) ->

  class AssignmentStub extends Backbone.Model
    name: -> @get('name')
    toView: =>
      name: @get('name')
      id: @id

  class Assignments extends Backbone.Collection
    model: AssignmentStub

  QUnit.module "NeverDropCollection",
    setup: ->
      list = [1..5]
      @assignments = new Assignments []
      @assignments.comparator = 'position'
      @assignments.reset((id: val, position:list.length-i, name: "Assignment #{val}") for val, i in list)
      @never_drops = new NeverDropCollection [],
        assignments: @assignments
        ag_id: 1

  test "#initialize", ->
    deepEqual @never_drops.assignments, @assignments
    strictEqual @never_drops.ag_id, 1

  test "#toAssignments", ->
    @never_drops.add {}
    @never_drops.add {}
    @never_drops.add {}
    @never_drops.add {}
    output = @never_drops.toAssignments @never_drops.at(3).get('chosen_id')
    expected = @assignments.slice(3).map (m) -> m.toView()
    deepEqual output, expected

  test "#findNextAvailable", ->
    @never_drops.add {}
    deepEqual @never_drops.findNextAvailable(), @never_drops.availableValues.get(@assignments.at(1).id), "finds the available item that has the id of the second assignment"

define [
  'Backbone'
  'compiled/models/AssignmentGroup'
], (Backbone, AssignmentGroup) ->

  class AssignmentGroupCollection extends Backbone.Collection

    model: AssignmentGroup

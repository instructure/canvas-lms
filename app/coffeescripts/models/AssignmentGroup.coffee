define [
  'Backbone'
  'compiled/models/Assignment'
], (Backbone, Assignment) ->

  class AssignmentGroup extends Backbone.Model
    resourceName: 'assignment_groups'

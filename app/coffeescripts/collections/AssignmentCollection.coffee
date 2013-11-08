define [
  'Backbone'
  'compiled/models/Assignment'
], (Backbone, Assignment) ->

  class AssignmentCollection extends Backbone.Collection

    model: Assignment

    comparator: 'position'

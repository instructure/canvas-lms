define [
  'Backbone'
  'compiled/collections/AssignmentOverrideCollection'
], ( {Model}, AssignmentOverrideCollection ) ->

  class Quiz extends Model

    initialize: ({assignment_overrides}) ->
      assignmentOverrides =
        new AssignmentOverrideCollection assignment_overrides
      @set 'assignment_overrides', assignmentOverrides, silent: true

    defaults:
      due_at: null
      unlock_at: null
      lock_at: null


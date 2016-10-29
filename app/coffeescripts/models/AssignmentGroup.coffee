define [
  'Backbone'
  'underscore'
  'compiled/backbone-ext/DefaultUrlMixin'
  'compiled/collections/AssignmentCollection'
], (Backbone, _, DefaultUrlMixin, AssignmentCollection) ->

  class AssignmentGroup extends Backbone.Model
    @mixin DefaultUrlMixin
    resourceName: 'assignment_groups'

    urlRoot: -> @_defaultUrl()

    initialize: ->
      if (assignments = @get('assignments'))?
        @set 'assignments', new AssignmentCollection(assignments)

    name: (newName) ->
      return @get 'name' unless arguments.length > 0
      @set 'name', newName

    position: (newPosition) ->
      return @get('position') || 0 unless arguments.length > 0
      @set 'position', newPosition

    groupWeight: (newWeight) ->
      return @get('group_weight') || 0 unless arguments.length > 0
      @set 'group_weight', newWeight

    rules: (newRules) ->
      return @get 'rules' unless arguments.length > 0
      @set 'rules', newRules

    removeNeverDrops: ->
      rules = @rules()
      if rules.never_drop
        delete rules.never_drop

    hasRules: ->
      @countRules() > 0

    countRules: ->
      rules = @rules() or {}
      aids = @assignmentIds()
      count = 0
      for k,v of rules
        if k == "never_drop"
          count += _.intersection(aids, v).length
        else
          count++
      count

    assignmentIds: ->
      assignments = @get('assignments')
      return [] unless assignments?
      assignments.pluck('id')

    canDelete: ->
      !@hasAssignmentDueInClosedGradingPeriod() && !@hasFrozenAssignments()

    hasFrozenAssignments: ->
      @get('assignments').any (m) ->
        m.get('frozen')

    hasAssignmentDueInClosedGradingPeriod: ->
      @get('has_assignment_due_in_closed_grading_period')

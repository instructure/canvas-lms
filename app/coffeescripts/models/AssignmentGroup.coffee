define [
  'Backbone'
  'compiled/backbone-ext/DefaultUrlMixin'
], (Backbone, DefaultUrlMixin) ->

  class AssignmentGroup extends Backbone.Model
    @mixin DefaultUrlMixin
    resourceName: 'assignment_groups'

    urlRoot: -> @_defaultUrl()

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

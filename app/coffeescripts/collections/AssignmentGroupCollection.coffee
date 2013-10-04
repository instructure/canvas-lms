define [
  'underscore'
  'Backbone'
  'compiled/models/AssignmentGroup'
], (_, Backbone, AssignmentGroup) ->

  class AssignmentGroupCollection extends Backbone.Collection

    model: AssignmentGroup

    @optionProperty 'course'

    # TODO: this will also return the assignments discussion_topic if it is of
    # that type, which we don't need.
    defaults:
      params:
        include: ["assignments"]

    loadModuleNames: ->
      $.get(ENV.URLS.context_modules_url).then (modules) =>
        moduleNames = {}
        for m in modules
          moduleNames[m.id] = m.name

        for assignment in @assignments()
          assignmentModuleNames = _(assignment.get 'module_ids')
            .map (id) -> moduleNames[id]
          assignment.set('modules', assignmentModuleNames)

    assignments: ->
      @chain()
        .map((ag) -> ag.get('assignments').toArray())
        .flatten()
        .value()

    comparator: 'position'

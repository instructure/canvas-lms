define [
  './base_controller'
  'i18n!add_module_item'
  '../../../shared/xhr/fetch_all_pages'
  'ic-ajax'
  '../../models/item'
], (Base, I18n, fetch, {request}, Item) ->

  AddAssignmentController = Base.extend

    # TODO: should move this to a model or something, or cache by URLs
    assignmentGroups: (->
      @constructor.groups or= fetch("/api/v1/courses/#{ENV.course_id}/assignment_groups?include[]=assignments")
    ).property()

    title: (->
      I18n.t('add_assignment_to', "Add an assignment to %{module}", module: @get('moduleController.name'))
    ).property('moduleController.name')

    actions:

      toggleSelected: (assignment) ->
        assignments = @get('model.selected')
        if assignments.contains(assignment)
          assignments.removeObject(assignment)
        else
          assignments.addObject(assignment)

  AddAssignmentController.reopenClass

    groups: null


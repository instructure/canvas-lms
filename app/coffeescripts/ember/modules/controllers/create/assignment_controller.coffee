define [
  './base_controller'
  'i18n!create_module_item'
  '../../../shared/xhr/fetch_all_pages'
  'ic-ajax'
  '../../models/item'
], (Base, I18n, fetch, {request}, Item) ->

  CreateAssignmentController = Base.extend

    text:
      assignmentName: I18n.t('assignment_name', 'Assignment Name')

    assignmentGroups: (->
      @constructor.groups or= fetch("/api/v1/courses/#{ENV.course_id}/assignment_groups")
    ).property()

    createItem: ->
      assignment = @get('model')
      item = Item.createRecord(title: assignment.name, type: 'Assignment')
      request(
        url: "/api/v1/courses/#{ENV.course_id}/assignments"
        type: 'post'
        data: assignment: assignment
      ).then(((savedAssignment) =>
        item.set('content_id', savedAssignment.id)
        item.save()
      ), (=>
        item.set('error', true)
      ))
      item

  CreateAssignmentController.reopenClass

    # simple cache so we don't fetch the groups over and over
    groups: null


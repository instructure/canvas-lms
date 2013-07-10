define [
  'i18n!assignments'
  'underscore'
  'compiled/collections/AssignmentCollection'
  'compiled/views/CollectionView'
  'compiled/views/assignments/AssignmentListItemView'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/assignments/CreateGroupView'
  'compiled/views/assignments/DeleteGroupView'
  'jst/assignments/teacher_index/AssignmentGroupListItem'
], (I18n, _, AssignmentCollection, CollectionView, AssignmentListItemView, CreateAssignmentView, CreateGroupView, DeleteGroupView, template) ->

  class AssignmentGroupListItemView extends CollectionView

    tagName: "li"
    itemView: AssignmentListItemView
    template: template

    @child 'createAssignmentView', '[data-view=createAssignment]'
    @child 'editGroupView', '[data-view=editAssignmentGroup]'
    @child 'deleteGroupView', '[data-view=deleteAssignmentGroup]'

    els: _.extend({}, @::els, {
      '.add_assignment': '$addAssignmentButton'
      '.delete_group': '$deleteGroupButton'
      '.edit_group': '$editGroupButton'
    })

    # call remove on children so that they can clean up old dialogs.
    # this should eventually happen at a higher level (eg for all views), but
    # we need to make sure that all children view are also children dom
    # elements first.
    render: ->
      @createAssignmentView.remove()
      @editGroupView.remove()
      super

    afterRender: ->
      # child views so they get rendered automatically, need to stop it
      @createAssignmentView.hide()
      @editGroupView.hide()
      @deleteGroupView.hide()
      # its trigger would not be rendered yet, set it manually
      @createAssignmentView.setTrigger @$addAssignmentButton
      @editGroupView.setTrigger @$editGroupButton
      @deleteGroupView.setTrigger @$deleteGroupButton

    initialize: ->
      @collection = new AssignmentCollection @model.get('assignments')
      @collection.on('add remove', @refreshDeleteDialog)
      super

      @editGroupView = new CreateGroupView
        assignmentGroup: @model
        assignments: @collection.models
      @createAssignmentView = new CreateAssignmentView
        assignmentGroup: @model
        collection: @collection
      @deleteGroupView = new DeleteGroupView
        model: @model
        assignments: @collection

    # this is the only way to get the number of assignments to update properly
    # when an assignment is created in a new assignment group (before refreshing the page)
    refreshDeleteDialog: =>
      @deleteGroupView.remove()
      @deleteGroupView = new DeleteGroupView
        model: @model
        assignments: @collection

    toJSON: ->
      count = @countRules()
      showRules = count != 0

      data = @model.toJSON()
      showWeight = @model.collection.course?.get('apply_assignment_group_weights')

      attributes = _.extend(data, {
        showRules: showRules
        rulesText: I18n.t('rules_text', "Rule", { count: count })
        showWeight: showWeight
        groupWeight: data.group_weight
      })

    countRules: ->
      rules = @model.get('rules')
      count = 0
      for k,v of rules
        if k == "never_drop"
          count += v.length
        else
          count++
      count

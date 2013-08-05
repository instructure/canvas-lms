define [
  'i18n!assignments'
  'underscore'
  'compiled/collections/AssignmentCollection'
  'compiled/views/CollectionView'
  'compiled/views/assignments/AssignmentListItemView'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/assignments/CreateGroupView'
  'jst/assignments/teacher_index/AssignmentGroupListItem'
], (I18n, _, AssignmentCollection, CollectionView, AssignmentListItemView, CreateAssignmentView, CreateGroupView, template) ->

  class AssignmentGroupListItemView extends CollectionView

    tagName: "li"
    itemView: AssignmentListItemView
    template: template

    @child 'createAssignmentView', '[data-view=createAssignment]'
    @child 'editGroupView', '[data-view=editAssignmentGroup]'

    els: _.extend({}, @::els, {
      '.add_assignment': '$addAssignmentButton'
      '.edit_group': '$editGroupButton'
    })

    afterRender: ->
      # child views so they get rendered automatically, need to stop it
      @createAssignmentView.hide()
      @editGroupView.hide()
      # its trigger would not be rendered yet, set it manually
      @createAssignmentView.setTrigger @$addAssignmentButton
      @editGroupView.setTrigger @$editGroupButton

    initialize: ->
      @collection = new AssignmentCollection @model.get('assignments')
      super

      @editGroupView = new CreateGroupView
        assignmentGroup: @model
        assignments: @collection.models
      @createAssignmentView = new CreateAssignmentView
        assignmentGroup: @model
        collection: @collection

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

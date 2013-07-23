define [
  'i18n!assignments'
  'underscore'
  'compiled/class/cache'
  'compiled/collections/AssignmentCollection'
  'compiled/views/CollectionView'
  'compiled/views/assignments/AssignmentListItemView'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/assignments/CreateGroupView'
  'compiled/views/assignments/DeleteGroupView'
  'jst/assignments/teacher_index/AssignmentGroupListItem'
], (I18n, _, Cache, AssignmentCollection, CollectionView, AssignmentListItemView, CreateAssignmentView, CreateGroupView, DeleteGroupView, template) ->

  class AssignmentGroupListItemView extends CollectionView
    tagName: "li"
    className: "item-group-condensed"
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

    events:
      'click .element_toggler': 'toggleArrow'

    messages:
      toggleMessage: I18n.t('toggle_message',"toggle assignment visibility")

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
      #listen for events that cause auto-expanding
      @collection.on('add', => if !@isExpanded() then @toggle() )

    initialize: ->
      @collection = new AssignmentCollection @model.get('assignments')
      @collection.on('add remove', @refreshDeleteDialog)
      modules = @model.collection.modules
      @collection.each (assign) ->
        assign.doNotParse()
        #set modules
        assign.modules modules[assign.id]
      super

      # we need the following line in order to access this view later
      @model.groupView = @
      @initCache()

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

    initCache: ->
      $.extend true, @, Cache
      @cache.use('localStorage')
      key = @cacheKey()
      if !@cache.get(key)?
        @cache.set(key, true)

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
        toggleMessage: @messages.toggleMessage
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

    isExpanded: ->
      @cache.get(@cacheKey())

    toggle: (setTo=false) ->
      @$el.find('.element_toggler').click()
      @cache.set(@cacheKey(), setTo)

    cacheKey: ->
      "ag_#{@model.id}_expanded"

    toggleArrow: (ev) ->
      arrow = $(ev.currentTarget).children('i')
      arrow.toggleClass('icon-mini-arrow-down').toggleClass('icon-mini-arrow-right')
      @toggleExpanded()

    toggleExpanded: ->
      key = @cacheKey()
      expanded = !@cache.get(key)
      @cache.set(key, expanded)

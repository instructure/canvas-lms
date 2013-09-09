define [
  'i18n!assignments'
  'underscore'
  'compiled/class/cache'
  'compiled/views/DraggableCollectionView'
  'compiled/views/assignments/AssignmentListItemView'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/assignments/CreateGroupView'
  'compiled/views/assignments/DeleteGroupView'
  'compiled/fn/preventDefault'
  'jst/assignments/AssignmentGroupListItem'
], (I18n, _, Cache, DraggableCollectionView, AssignmentListItemView, CreateAssignmentView, CreateGroupView, DeleteGroupView, preventDefault, template) ->

  class AssignmentGroupListItemView extends DraggableCollectionView
    @optionProperty 'course'

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
      'click .tooltip_link': preventDefault ->

    messages:
      toggleMessage: I18n.t('toggle_message', "toggle assignment visibility")

    # call remove on children so that they can clean up old dialogs.
    # this should eventually happen at a higher level (eg for all views), but
    # we need to make sure that all children view are also children dom
    # elements first.
    render: ->
      @createAssignmentView.remove() if @createAssignmentView
      @editGroupView.remove() if @editGroupView
      @deleteGroupView.remove() if @deleteGroupView
      super(@canManage())

    afterRender: ->
      # need to hide child views and set trigger manually
      if @createAssignmentView
        @createAssignmentView.hide()
        @createAssignmentView.setTrigger @$addAssignmentButton

      if @editGroupView
        @editGroupView.hide()
        @editGroupView.setTrigger @$editGroupButton

      if @deleteGroupView
        @deleteGroupView.hide()
        @deleteGroupView.setTrigger @$deleteGroupButton

      if @model.hasRules()
        @createRulesToolTip()

    createRulesToolTip: =>
      link = @$el.find('.tooltip_link')
      link.tooltip
        position:
          my: 'center top'
          at: 'center bottom+10'
          collision: 'fit fit'
        tooltipClass: 'center top vertical'
        content: ->
          $(link.data('tooltipSelector')).html()

    initialize: ->
      @initializeCollection()
      super
      @initializeChildViews()

      # we need the following line in order to access this view later
      @model.groupView = @
      @initCache()

    initializeCollection: ->
      @model.get('assignments').each (assign) ->
        assign.doNotParse() if assign.multipleDueDates()

      @collection = @model.get('assignments')
      @collection.on 'add', @expand

    initializeChildViews: ->
      @editGroupView = false
      @createAssignmentView = false
      @deleteGroupView = false

      if @canManage()
        @editGroupView = new CreateGroupView
          assignmentGroup: @model
        @createAssignmentView = new CreateAssignmentView
          assignmentGroup: @model
        @deleteGroupView = new DeleteGroupView
          model: @model

    initCache: ->
      $.extend true, @, Cache
      @cache.use('localStorage')
      key = @cacheKey()
      if !@cache.get(key)?
        @cache.set(key, true)

    toJSON: ->
      data = @model.toJSON()
      showWeight = @course?.get('apply_assignment_group_weights') and data.group_weight?

      attributes = _.extend(data, {
        showRules: @model.hasRules()
        rulesText: I18n.t('rules_text', "Rule", { count: @model.countRules() })
        displayableRules: @displayableRules()
        showWeight: showWeight
        groupWeight: data.group_weight
        toggleMessage: @messages.toggleMessage
        hasFrozenAssignments: @model.hasFrozenAssignments? and @model.hasFrozenAssignments()
      })

    displayableRules: ->
      rules = @model.rules() or {}
      results = []

      if rules.drop_lowest? and rules.drop_lowest > 0
        results.push(I18n.t('drop_lowest_rule', {
          'one': 'Drop the lowest score',
          'other': 'Drop the lowest %{count} scores'
        }, {
          'count': rules.drop_lowest
        }))

      if rules.drop_highest? and rules.drop_highest > 0
        results.push(I18n.t('drop_highest_rule', {
          'one': 'Drop the highest score',
          'other': 'Drop the highest %{count} scores'
        }, {
          'count': rules.drop_highest
        }))

      if rules.never_drop? and rules.never_drop.length > 0
        _.each rules.never_drop, (never_drop_assignment_id) =>
          assign = @model.get('assignments').findWhere(id: never_drop_assignment_id)

          # TODO: students won't see never drop rules for unpublished
          # assignments because we don't know if the assignment is missing
          # because it is unpublished or because it has been moved or deleted.
          # Once those cases are handled better, we can add a default here.
          if name = assign?.get('name')
            results.push(I18n.t('never_drop_rule', 'Never drop %{assignment_name}', {
              'assignment_name': name
            }))

      results

    isExpanded: ->
      @cache.get(@cacheKey())

    expand: =>
      @toggle(true) if !@isExpanded()

    toggle: (setTo=false) ->
      @$el.find('.element_toggler').click()
      @cache.set(@cacheKey(), setTo)

    cacheKey: ->
      ["course", @course.get('id'), "user", @currentUserId(), "ag", @model.get('id'), "expanded"]

    toggleArrow: (ev) ->
      arrow = $(ev.currentTarget).children('i')
      arrow.toggleClass('icon-mini-arrow-down').toggleClass('icon-mini-arrow-right')
      @toggleExpanded()

    toggleExpanded: ->
      key = @cacheKey()
      expanded = !@cache.get(key)
      @cache.set(key, expanded)

    canManage: ->
      ENV.PERMISSIONS.manage

    currentUserId: ->
      ENV.current_user_id

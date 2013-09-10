define [
  'i18n!assignments'
  'underscore'
  'compiled/class/cache'
  'compiled/views/DraggableCollectionView'
  'compiled/views/assignments/AssignmentListItemView'
  'compiled/views/assignments/CreateAssignmentView'
  'compiled/views/assignments/CreateGroupView'
  'compiled/views/assignments/DeleteGroupView'
  'compiled/views/MoveDialogView'
  'compiled/fn/preventDefault'
  'jst/assignments/AssignmentGroupListItem'
], (I18n, _, Cache, DraggableCollectionView, AssignmentListItemView, CreateAssignmentView, CreateGroupView, DeleteGroupView, MoveDialogView, preventDefault, template) ->

  class AssignmentGroupListItemView extends DraggableCollectionView
    @optionProperty 'course'

    tagName: "li"
    className: "item-group-condensed"
    itemView: AssignmentListItemView
    template: template

    @child 'createAssignmentView', '[data-view=createAssignment]'
    @child 'editGroupView', '[data-view=editAssignmentGroup]'
    @child 'deleteGroupView', '[data-view=deleteAssignmentGroup]'
    @child 'moveGroupView', '[data-view=moveAssignmentGroup]'

    els: _.extend({}, @::els, {
      '.add_assignment': '$addAssignmentButton'
      '.delete_group': '$deleteGroupButton'
      '.edit_group': '$editGroupButton'
      '.move_group': '$moveGroupButton'
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
    render: =>
      @createAssignmentView.remove() if @createAssignmentView
      @editGroupView.remove() if @editGroupView
      @deleteGroupView.remove() if @deleteGroupView
      @moveGroupView.remove() if @moveGroupView
      super(@canManage())

      # reset the model's view property; it got overwritten by child views
      @model.view = this if @model

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

      if @moveGroupView
        @moveGroupView.hide()
        @moveGroupView.setTrigger @$moveGroupButton

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
      @collection.on 'add',  => @expand(false)

    initializeChildViews: ->
      @editGroupView = false
      @createAssignmentView = false
      @deleteGroupView = false
      @moveGroupView = false

      if @canManage()
        @editGroupView = new CreateGroupView
          assignmentGroup: @model
        @createAssignmentView = new CreateAssignmentView
          assignmentGroup: @model
        @deleteGroupView = new DeleteGroupView
          model: @model
        @moveGroupView = new MoveDialogView
          model: @model
          saveURL: -> ENV.URLS.sort_url

    initCache: ->
      $.extend true, @, Cache
      @cache.use('localStorage')
      key = @cacheKey()
      if !@cache.get(key)?
        @cache.set(key, true)

    toJSON: ->
      data = @model.toJSON()
      showWeight = @course?.get('apply_assignment_group_weights') and data.group_weight?
      canMove = @model.collection.length > 1

      attributes = _.extend(data, {
        canMove: canMove
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

    search: (regex) ->
      atleastone = false
      @collection.each (as) =>
        atleastone = true if as.assignmentView.search(regex)
      if atleastone
        @show()
        @expand(false)
      else
        @hide()
      atleastone

    endSearch: ->
      @show()
      @collapseIfNeeded()
      @resetNoToggleCache()
      @collection.each (as) =>
        as.assignmentView.endSearch()

    shouldBeExpanded: ->
      @cache.get(@cacheKey())

    collapseIfNeeded: ->
      @collapse(false) unless @shouldBeExpanded()

    expand: (toggleCache=true) =>
      @_setNoToggleCache() unless toggleCache
      @toggleCollapse() unless @currentlyExpanded()

    collapse: (toggleCache=true) =>
      @_setNoToggleCache() unless toggleCache
      @toggleCollapse() if @currentlyExpanded()

    toggleCollapse: (toggleCache=true) ->
      @_setNoToggleCache() unless toggleCache
      @$el.find('.element_toggler').click()

    _setNoToggleCache: ->
      @$el.find('.element_toggler').data("noToggleCache", true)

    currentlyExpanded: ->
      # the 2 states of the element toggler are true and "false"
      if @$el.find('.element_toggler').attr("aria-expanded") == "false"
        false
      else
        true

    cacheKey: ->
      ["course", @course.get('id'), "user", @currentUserId(), "ag", @model.get('id'), "expanded"]

    toggleArrow: (ev) =>
      arrow = $(ev.currentTarget).children('i')
      arrow.toggleClass('icon-mini-arrow-down').toggleClass('icon-mini-arrow-right')
      @toggleCache() unless $(ev.currentTarget).data("noToggleCache")
      #reset noToggleCache because it is a one-time-use-only flag
      @resetNoToggleCache(ev.currentTarget)

    resetNoToggleCache: (selector=null) ->
      if selector?
        obj = $(selector)
      else
        obj = @$el.find('.element_toggler')
      obj.data("noToggleCache", false)

    toggleCache: ->
      key = @cacheKey()
      expanded = !@cache.get(key)
      @cache.set(key, expanded)

    canManage: ->
      ENV.PERMISSIONS.manage

    currentUserId: ->
      ENV.current_user_id

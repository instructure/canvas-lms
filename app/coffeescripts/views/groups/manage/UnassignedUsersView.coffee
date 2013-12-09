define [
  'underscore'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'jst/groups/manage/groupUsers'
], (_, GroupUsersView, AssignToGroupMenu, template) ->

  class UnassignedUsersView extends GroupUsersView

    @optionProperty 'groupsCollection'
    @optionProperty 'category'

    defaults: _.extend {},
      GroupUsersView::defaults,
      autoFetch: true # load until below the viewport, don't wait for the user to scroll
      itemViewOptions:
        canAssignToGroup: true
        canEditGroupAssignment: false

    dropOptions:
      accept: '.group-user'
      activeClass: 'droppable'
      hoverClass: 'droppable-hover'
      tolerance: 'pointer'

    attach: ->
      @collection.on 'reset', @render
      @collection.on 'moved', @highlightUser

    afterRender: ->
      super
      @collection.load('first')
      @$el.parent().droppable(_.extend({}, @dropOptions))
                   .on('drop', @_onDrop)

    toJSON: ->
      loading: !@collection.loadedAll
      count: @collection.length

    remove: ->
      @assignToGroupMenu?.remove()
      super

    events:
      'click .assign-to-group': 'showAssignToGroup'
      'focus .assign-to-group': 'showAssignToGroup'
      'blur .assign-to-group': 'hideAssignToGroup'

    showAssignToGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      @assignToGroupMenu ?= new AssignToGroupMenu collection: @groupsCollection
      @assignToGroupMenu.model = @collection.get($target.data('user-id'))
      @assignToGroupMenu.showBy $target

    hideAssignToGroup: ->
      @assignToGroupMenu.hide()

    canAssignToGroup: ->
      @options.canAssignToGroup and @groupsCollection.length

    ##
    # handle drop events on '.unassigned-students'
    # ui.draggable: the user being dragged
    _onDrop: (e, ui) =>
      user = ui.draggable.data('model')
      setTimeout =>
        @category.reassignUser(user, null)

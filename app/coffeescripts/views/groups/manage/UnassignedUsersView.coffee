define [
  'underscore'
  'compiled/views/groups/manage/GroupUsersView'
  'compiled/views/groups/manage/AssignToGroupMenu'
  'jst/groups/manage/groupUsers'
], (_, GroupUsersView, AssignToGroupMenu, template) ->

  class UnassignedUsersView extends GroupUsersView

    @optionProperty 'assignToGroupMenu'
    @optionProperty 'groupsCollection'

    defaults: _.extend {},
      GroupUsersView::defaults,
      autoFetch: true # load until below the viewport, don't wait for the user to scroll
      itemViewOptions:
        canAssignToGroup: true
        canRemoveFromGroup: false

    attach: ->
      @groupsCollection.on 'add', @groupAdded
      @groupsCollection.on 'remove', @groupRemoved

    afterRender: ->
      super
      @collection.load('first')

    toJSON: ->
      loading: !@collection.loadedAll
      count: @collection.length

    remove: ->
      @assignToGroupMenu.remove()
      super

    events:
      'click .assign-to-group': 'showAssignToGroup'
      'focus .assign-to-group': 'showAssignToGroup'
      'blur .assign-to-group': 'hideAssignToGroup'

    showAssignToGroup: (e) ->
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.currentTarget)
      @assignToGroupMenu.model = @collection.get($target.data('user-id'))
      @assignToGroupMenu.showBy $target

    hideAssignToGroup: ->
      @assignToGroupMenu.hide()

    canAssignToGroup: ->
      @options.canAssignToGroup and @groupsCollection.length

    groupAdded: =>
      @$el.removeClass 'group-category-empty'

    groupRemoved: (group) =>
      users = group.users()
      if users.loadedAll
        users = users.models.slice()
        user.set 'groupId', null for user in users
      else
        @collection.fetch()
      @$el.addClass 'group-category-empty' if @groupsCollection.length is 0


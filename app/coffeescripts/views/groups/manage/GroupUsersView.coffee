define [
  'underscore'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/groups/manage/GroupUserView'
  'jst/groups/manage/groupUsers'
], (_, PaginatedCollectionView, GroupUserView, template) ->

  class GroupUsersView extends PaginatedCollectionView

    @optionProperty 'assignToGroupMenu'

    @optionProperty 'groupsCollection'

    initialize: (options) ->
      super _.extend {}, options,
        itemView: GroupUserView
        itemViewOptions:
          canAssignToGroup: options.canAssignToGroup
      if @options.canAssignToGroup and @assignToGroupMenu
        @groupsCollection.on "add remove", @toggleGroupClass

    template: template

    events:
      'click .assign-to-group': 'showAssignToGroup'
      'focus .assign-to-group': 'showAssignToGroup'
      'blur .assign-to-group': 'hideAssignToGroup'

    showAssignToGroup: (e) =>
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.target)
      @assignToGroupMenu.model = @collection.get(parseInt($target.data('user-id'), 10))
      @assignToGroupMenu.showBy $target

    hideAssignToGroup: =>
      @assignToGroupMenu.hide()

    canAssignToGroup: ->
      @options.canAssignToGroup and @groupsCollection.length

    toggleGroupClass: =>
      @$el.toggleClass 'group-category-empty', @groupsCollection.length is 0

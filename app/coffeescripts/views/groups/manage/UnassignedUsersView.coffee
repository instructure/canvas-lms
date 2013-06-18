define [
  'Backbone'
  'underscore'
  'compiled/views/PaginatedCollectionView'
  'jst/groups/manage/unassignedUsers'
  'jst/groups/manage/unassignedUser'
], ({View}, _, PaginatedCollectionView, unassignedUsersTemplate, unassignedUserTemplate) ->

  class UnassignedUsersView extends PaginatedCollectionView

    @optionProperty 'groupId'

    initialize: (options) ->
      super _.extend {}, options,
        itemView: View
        itemViewOptions:
          template: unassignedUserTemplate

    template: unassignedUsersTemplate

    events:
      'click .assign-to-group': 'setGroup'

    attach: ->
      @collection.on 'add remove change reset', @render, this

    setGroup: (e) =>
      e.preventDefault()
      e.stopPropagation()
      $target = $(e.target)
      user = @collection.get($target.data('user-id'))
      user.save({'groupId': @groupId})

    toJSON: ->
      users: @collection.toJSON()
      groupId: @groupId
define [
  'Backbone'
  'underscore'
  'compiled/views/CollectionView'
  'jst/groups/manage/addUnassignedUsers'
  'jst/groups/manage/addUnassignedUser'
], ({View}, _, CollectionView, template, itemTemplate) ->

  class AddUnassignedUsersView extends CollectionView

    initialize: (options) ->
      super _.extend {}, options,
        itemView: View.extend tagName: 'li'
        itemViewOptions:
          template: itemTemplate

    template: template

    attach: ->
      @collection.on 'add remove change reset', @render
      @collection.on 'setParam deleteParam', @checkParam

    checkParam: (param, value) =>
      @lastRequest?.abort()
      @collection.termError = value is false
      if value
        @lastRequest = @collection.fetch()
      else
        @render()

    toJSON: ->
      users: @collection.toJSON()
      term: @collection.options.params?.search_term
      termError: @collection.termError

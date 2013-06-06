define [
  'compiled/collections/PaginatedCollection'
], (PaginatedCollection) ->

  class GroupUserCollection extends PaginatedCollection
    @collectionMap = {}

    @optionProperty 'groupId'

    initialize: (options) ->
      super
      @on 'change:groupId', @updateGroupId
      GroupUserCollection.collectionMap[@groupId] = this

    updateGroupId: (model, groupId) =>
      @remove model
      GroupUserCollection.collectionMap[groupId]?.add model

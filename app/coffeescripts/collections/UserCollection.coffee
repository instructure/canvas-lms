define [
  'Backbone'
  'compiled/collections/PaginatedCollection'
  'compiled/models/User'
], (Backbone, PaginatedCollection, User) ->

  class UserCollection extends PaginatedCollection

    model: User
define [
  'compiled/collections/PaginatedCollection'
], (PaginatedCollection) ->

  class UserObserveesCollection extends PaginatedCollection
    url: -> "/api/v1/users/#{@user_id}/observees"

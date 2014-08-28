define [
  'jquery'
  'Backbone'
  'compiled/collections/PaginatedCollection'
], ($, Backbone, PaginatedCollection) ->
  class WrappedCollection extends PaginatedCollection
    @optionProperty 'key'

    parse: (response) ->
      @linked = response.linked
      response[@key]

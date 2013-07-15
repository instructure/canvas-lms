define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/WikiPage'
], (PaginatedCollection, WikiPage) ->

  class WikiPageCollection extends PaginatedCollection
    model: WikiPage

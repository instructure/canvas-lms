define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/Outcome'
], (PaginatedCollection, Outcome) ->

  class OutcomeCollection extends PaginatedCollection
    model: Outcome
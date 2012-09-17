define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/OutcomeGroup'
], (PaginatedCollection, OutcomeGroup) ->

  class OutcomeGroupCollection extends PaginatedCollection
    model: OutcomeGroup
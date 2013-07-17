define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/ExternalTool'
], (PaginatedCollection, ExternalTool) ->

  class ExternalToolCollection extends PaginatedCollection
    model: ExternalTool

define [
  'Backbone'
  'underscore'
  'compiled/models/KollectionItem'
], (Backbone, _, KollectionItem) ->

  class KollectionItemCollection extends Backbone.Collection
    model: KollectionItem
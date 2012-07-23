define [
  'Backbone'
  'underscore'
  'compiled/models/Kollection'
], (Backbone, _, Kollection) ->

  class KollectionCollection extends Backbone.Collection
    url: '/api/v1/users/self/collections'
    model: Kollection

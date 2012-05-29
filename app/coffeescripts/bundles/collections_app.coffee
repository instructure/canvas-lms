require [
  'Backbone'
  'compiled/routers/KollectionsRouter'
  'compiled/behaviors/handleBackboneLinks'
], (Backbone, KollectionsRouter) ->

  new KollectionsRouter()
  Backbone.history.start pushState: true

require [
  'Backbone'
  'compiled/discussions/TopicView'
], (Backbone, TopicView) ->

  $ ->
    app = new TopicView model: new Backbone.Model

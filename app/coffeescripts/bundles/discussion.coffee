require [
  'compiled/backbone-ext/Backbone'
  'compiled/discussions/TopicView'
], (Backbone, TopicView) ->

  $ ->
    app = new TopicView model: new Backbone.Model


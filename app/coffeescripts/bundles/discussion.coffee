require [
  'Backbone'
  'compiled/discussions/app'
  'compiled/discussions/TopicView'
  'compiled/discussions/ParticipantCollection'
], (Backbone, app, TopicView, ParticipantCollection) ->

  @app = app

  $ ->
    app.topicView = new TopicView model: new Backbone.Model


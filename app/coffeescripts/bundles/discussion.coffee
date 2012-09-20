require [
  'Backbone'
  'compiled/discussions/app'
  'compiled/views/DiscussionTopic/TopicView'
  'compiled/collections/ParticipantCollection'
], (Backbone, app, TopicView, ParticipantCollection) ->

  @app = app

  $ ->
    app.topicView = new TopicView model: new Backbone.Model


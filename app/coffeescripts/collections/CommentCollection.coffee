define [
  'Backbone'
  'compiled/models/Comment'
], (Backbone, Comment) ->

  class CommentCollection extends Backbone.Collection

    model: Comment


define [
  'Backbone'
  'underscore'
  'compiled/fn/preventDefault'
  'jst/CommentsView'

  # needed by CommentsView
  'jst/_avatar'
], (Backbone, _, preventDefault, template) ->

  class CommentsView extends Backbone.View

    template: template

    events:
      'submit form' : 'addNewComment'
      'click [data-delete-comment]': 'deleteComment'

    initialize: ->
      super
      @render()
      @model.entries.on 'all', @render

    toJSON: ->
      entries: @model.entries.map (entry) ->
        _.extend entry.toJSON(),
          author:    entry.author()
          editor:    entry.editor()
          canDelete: entry.author()?.id is ENV.current_user?.id
      currentUser: ENV.current_user

    deleteComment: preventDefault ({target}) ->
      id = @$(target).data('deleteComment')
      @model.entries.get(id).destroy()

    addNewComment: preventDefault ->
      return unless message = @$('[name="message"]').val()
      entry = @model.entries.create
        # convert newlines to breaks before we send it to the server
        message: message.replace(/\n/g, "<br />")
      # wait till after the sync request to set user_id because API chokes if it is present
      # but set it so that it doesn't show up in the view as 'unknown author'
      entry.set 'user_id', ENV.current_user_id

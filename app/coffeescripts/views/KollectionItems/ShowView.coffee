define [
  'Backbone'
  'underscore'
  'compiled/views/CommentsView'
  'jst/KollectionItems/ShowView'
], (Backbone, _, CommentsView, template) ->

  class KollectionItemShowView extends Backbone.View

    template: template

    events:
      # TODO abstract handleClick
      'click [data-event]' : 'handleClick'

    initialize: ->
      @model.on 'change reset', @render
      @toggleComments(true) if @options.fullView


    onCommentButtonClick: ->
      if @options.fullView
        @$('[name="message"]').focus()
      else
        @toggleComments !@showingComments

    toggleComments: (enable)->
      return if enable is @showingComments #dont do anything if not changing
      @showingComments = enable
      if enable
        @commentsView ||= new CommentsView(model: @model.commentTopic)
        @options.views = commentsView: @commentsView
        @model.commentTopic.fetchEntries()
      else
        delete @options.views
      @render()

    toJSON: ->
      _.extend super,
        comments_count: @model.commentTopic.entries.length || '&nbsp;'
        fullView:  @options.fullView

    # TODO abstract handleClick
    handleClick: (event) ->
      event.preventDefault()
      event.stopPropagation()
      method = @$(event.currentTarget).data 'event'
      @[method]?(arguments...)

define [
  'compiled/models/Progress'
  'underscore'
], (Progress, _) ->

  # Mixin to models that work with the Progress API.
  #
  # When you call `save` on your model, and the server returns
  # a `progress_url` attribute, this mixin will set up a progress model
  # and start polling 
  #
  # The progress model is availabel via @progressModel.
  #
  # @event progressResolved - fires when the progress is complete

  progressable =

    initialize: ->
      @progressModel = new Progress
      @attachProgressable()

    # Returns the progressModel.pollDfd instead of the @save deferred
    saveWithProgressDeferred: ->
      @save()
      @progressModel.pollDfd

    attachProgressable: ->
      @on 'change:progress_url', (model, url) =>
        @progressModel.set({url, workflow_state: 'queued'})
      @progressModel.on 'complete', =>
        @fetch success: =>
          @trigger 'progressResolved'


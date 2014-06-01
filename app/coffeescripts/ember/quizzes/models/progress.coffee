define [
  'ember'
  'ember-data'
], ({Deferred}, {Model, attr}) ->
  # The Progress model represents the progress of an async operation happening
  # in the back-end that may take some time to complete. The model provides an
  # interface to track the completion of this operation.
  Model.extend
    tag: attr('string')
    completion: attr('number')
    # workflowState can be any one of:
    #
    # - undefined: the operation hasn't started
    # - "queued": the operation is pending and will start soon
    # - "running": the operation is being performed
    # - "completed": the operation was completed successfully
    # - "failed": the operation failed
    workflowState: attr('string')
    message: attr('string')
    createdAt: attr('date')
    updatedAt: attr('date')

    # Kick off a poller that will track the completion of the operation.
    #
    # @param [Integer] [pollingInterval=1000]
    #   How often to poll the operation for its completion, in milliseconds.
    #
    # @return [Ember.Deferred]
    #   A promise that will yield only when the operation is complete.
    trackCompletion: (pollingInterval) ->
      service = new Deferred()

      Ember.run.later this, ->
        poll = null
        timeout = null

        # don't try to do any ajax when we're leaving the page
        # workaround for https://code.google.com/p/chromium/issues/detail?id=263981
        $(window).on 'beforeunload', -> clearTimeout(timeout)

        poll = =>
          @reload().then =>
            if @get('workflowState') == 'failed'
              service.reject()
            else if @get('workflowState') == 'completed'
              service.resolve()
            else
              timeout = setTimeout poll, pollingInterval || 1000
        poll()

      service
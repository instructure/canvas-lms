define ['Backbone'], ({Model}) ->

  # Works with the progress API. Will poll its url until the `workflow_state`
  # is completed.
  #
  # Has a @pollDfd object that you can use to do things when the job is
  # complete.
  #
  # @event complete - triggered when the polling stops and the job is
  # complete.

  class Progress extends Model

    defaults:

      # The url to poll
      url: null

      # How long after a response to fetch again
      timeout: 1000

    # Array of states to continue polling for progress
    pollStates: ['queued', 'running']

    initialize: ->
      @pollDfd = new $.Deferred

    url: ->
      @get 'url'

    # Fetches the model from the server on an interval, will trigger
    # 'complete' event when finished. Returns a deferred that resolves
    # when the server side job finishes
    #
    # @returns {Deferred}
    # @api public

    poll: ->
      @fetch().then =>
        @onPoll()
      , =>
        @pollDfd.rejectWith this, arguments
      @pollDfd

    # Called on each poll fetch
    #
    # @api private

    onPoll: ->
      if @get('workflow_state') in @pollStates
        setTimeout (=> @poll()), @get('timeout')
      else
        @pollDfd.resolve()
        @trigger 'complete'


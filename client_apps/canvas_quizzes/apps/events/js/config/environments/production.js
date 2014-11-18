define([], function() {
  /**
   * @class Events.Config
   */
  return {
    /**
     * @cfg {Function} ajax
     * An XHR request processor that has an API compatible with jQuery.ajax.
     */
    ajax: undefined,

    /**
     * @cfg {String} quizUrl
     * Canvas API endpoint for querying the current quiz.
     */
    quizUrl: undefined,

    /**
     * @cfg {String} submissionUrl
     * Canvas API endpoint for querying the current quiz submission.
     */
    submissionUrl: undefined,

    /**
     * @cfg {String} eventsUrl
     * Canvas API endpoint for querying the current quiz submission's events.
     */
    eventsUrl: undefined,

    /**
     * @cfg {String} questionsUrl
     * Canvas API endpoint for querying questions in the current quiz.
     */
    questionsUrl: undefined,

    attempt: undefined,

    /**
     * @cfg {Boolean} [loadOnStartup=true]
     *
     * Whether the app should query all the data it needs as soon as it is
     * mounted.
     *
     * You may disable this behavior if you want to manually inject the app
     * with data.
     */
    loadOnStartup: true,

    /**
     * Error emitter. Default behavior is to log the error message to the
     * console.
     *
     * Override this to handle errors from the app.
     *
     * @param  {String} message
     *         An explanation of the error.
     */
    onError: function(message) {
      console.error(message);
    }
  };
});

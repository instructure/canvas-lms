define([], function() {
  /**
   * @class Config
   * Application-wide configuration.
   *
   * Some parameters are required to be set up correctly before the app is
   * mounted for it to work properly.
   *
   * === Example: configuring the app
   *
   *     require([ 'path/to/app' ], function(app) {
   *       app.configure({
   *         precision: 2,
   *         ajax: $.ajax
   *       });
   *     });
   */
  return {
    /**
     * @cfg {Number} [precision=2]
     *
     * Number of decimals to round to when displaying floats.
     */
    precision: 2,

    /**
     * @cfg {Function} ajax
     * An XHR request processor that has an API compatible with jQuery.ajax.
     */
    ajax: undefined,

    /**
     * @cfg {String} quizStatisticsUrl
     * Canvas API endpoint for querying the current quiz's statistics.
     */
    quizStatisticsUrl: undefined,

    /**
     * @cfg {String} quizReportsUrl
     * Canvas API endpoint for querying the current quiz's statistic reports.
     */
    quizReportsUrl: undefined,

    /**
     * @cfg {Boolean} [includesAllVersions=true]
     * Whether we should get the statistics and quiz reports for all versions
     * of the quiz, instead of the latest.
     */
    includesAllVersions: true,

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
     * @cfg {Number} pollingFrequency
     * Milliseconds to wait before polling the completion of progress objects.
     */
    pollingFrequency: 1000,

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

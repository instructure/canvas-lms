define(function(require) {
  var quizStatistics = require('../stores/statistics');
  var quizReports = require('../stores/reports');
  var config = require('../config');
  var update;

  var onChange = function() {
    update({
      quizStatistics: quizStatistics.get(),
      isLoadingStatistics: quizStatistics.isLoading(),
      quizReports: quizReports.getAll(),
    });
  };

  /**
   * @class Core.Controller
   * @private
   *
   * The controller is responsible for keeping the UI up-to-date with the
   * data layer.
   */
  var Controller = {

    /**
     * Start listening to data updates.
     *
     * @param {Function} onUpdate
     *        A callback to notify when new data comes in.
     *
     * @param {Object} onUpdate.props
     *        A set of props ready for injecting into the app layout.
     *
     * @param {Object} onUpdate.props.quizStatistics
     *        Quiz statistics.
     *        See Stores.Statistics#getQuizStatistics().
     *
     * @param {Object} onUpdate.props.quizReports
     *        Quiz reports.
     *        See Stores.Statistics#getQuizReports().
     */
    start: function(onUpdate) {
      update = onUpdate;
      quizStatistics.addChangeListener(onChange);
      quizReports.addChangeListener(onChange);

      if (config.loadOnStartup) {
        Controller.load();
      }
    },

    /**
     * Load initial application data; quiz statistics and reports.
     */
    load: function() {
      if (config.quizStatisticsUrl) {
        quizStatistics.load();
        quizReports.load();
      }
      else {
        console.warn(
          'You have requested to load on start-up, but have not',
          'provided a url to load from in CQS.config.quizStatisticsUrl.'
        );
      }
    },

    /**
     * Stop listening to data changes.
     */
    stop: function() {
      quizStatistics.removeChangeListener(onChange);
      quizReports.removeChangeListener(onChange);
      update = undefined;
    }
  };

  return Controller;
});
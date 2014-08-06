define(function(require) {
  var statisticsStore = require('../stores/statistics');
  var config = require('../config');
  var update;

  var onChange = function() {
    update({
      quizStatistics: statisticsStore.getQuizStatistics(),
      quizReports: statisticsStore.getQuizReports(),
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
      statisticsStore.addChangeListener(onChange);

      if (config.loadOnStartup) {
        Controller.load();
      }
    },

    /**
     * Load initial application data; quiz statistics and reports.
     */
    load: function() {
      if (config.quizStatisticsUrl) {
        statisticsStore.load();
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
      statisticsStore.removeChangeListener(onChange);
      update = undefined;
    }
  };

  return Controller;
});
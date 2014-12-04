define(function(require) {
  var EventStore = require('../stores/events');
  var config = require('../config');
  var update;

  var onChange = function() {
    update({
      submission: EventStore.getSubmission(),
      questions: EventStore.getQuestions(),
      events: EventStore.getAll(),
      currentEventId: EventStore.getCursor(),
      isLoadingQuestion: EventStore.isLoadingQuestion(),
      inspectedQuestion: EventStore.getInspectedQuestion(),
      inspectedQuestionId: EventStore.getInspectedQuestionId(),
      attempt: EventStore.getAttempt(),
      availableAttempts: EventStore.getAvailableAttempts(),
    });
  };

  /**
   * @class Events.Core.Controller
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
      EventStore.addChangeListener(onChange);

      if (config.loadOnStartup) {
        Controller.load();
      }
    },

    /**
     * Load initial application data; quiz statistics and reports.
     */
    load: function() {
      EventStore.loadInitialData().then(EventStore.load.bind(EventStore));
    },

    /**
     * Stop listening to data changes.
     */
    stop: function() {
      update = undefined;
    }
  };

  return Controller;
});
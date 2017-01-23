define((require) => {
  const Store = require('canvas_quizzes/core/store');
  const Dispatcher = require('../core/dispatcher');
  const config = require('../config');
  const QuizStats = require('../collections/quiz_statistics');
  const populateCollection = require('./common/populate_collection');
  const quizStats = new QuizStats([]);

  /**
   * @class Statistics.Stores.Statistics
   * Load stats.
   */
  const store = new Store('statistics', {
    getInitialState () {
      return {
        loading: false,
        stats_can_load: true,
      };
    },

    /**
     * Load quiz statistics.
     *
     * @needs_cfg quizStatisticsUrl
     * @async
     * @fires change
     *
     * @return {RSVP.Promise}
     *         Fulfills when the stats have been loaded and injected.
     */
    load () {
      if (!config.quizStatisticsUrl) {
        return config.onError('Missing configuration parameter "quizStatisticsUrl".');
      }

      this.setState({ loading: true });

      return quizStats.fetch({
        success: this.checkForStatsNoLoad.bind(this),
      }).then((payload) => {
        this.populate(payload);
        this.setState({ loading: false });
      });
    },

    checkForStatsNoLoad (collection, response) {
      if (response == null) {
        this.setState({ stats_can_load: false });
      }
    },

    /**
     * Populate the store with pre-loaded statistics data you've received from
     * the Canvas stats index endpoint (JSON-API or JSON).
     *
     * @fires change
     */
    populate (payload) {
      populateCollection(quizStats, payload);
      this.emitChange();
    },

    get () {
      let props;

      if (quizStats.length) {
        props = quizStats.first().toJSON();
        // props.expandingAll = this.isExpandingAll();
      }

      return props;
    },

    isLoading () {
      return this.state.loading;
    },

    canBeLoaded () {
      return this.state.stats_can_load;
    },

    getSubmissionStatistics () {
      const stats = this.get();
      if (stats) {
        return stats.submissionStatistics;
      }
    },

    getQuestionStatistics () {
      const stats = this.get();

      if (stats) {
        return stats.questionStatistics;
      }
    },

    filterForSection (sectionId) {
      if (sectionId == 'all') {
        quizStats.url = config.quizStatisticsUrl;
      } else {
        quizStats.url = `${config.quizStatisticsUrl}?section_ids=${sectionId}`;
      }

      config.section_ids = sectionId;
      this.setState({ loading: true });

      return quizStats.fetch({
        success: this.checkForStatsNoLoad.bind(this),
      }).then((payload) => {
        this.populate(payload);
        this.setState({ loading: false });
      });
    },

    __reset__ () {
      quizStats.reset();
      return Store.prototype.__reset__.call(this);
    }
  }, Dispatcher);

  return store;
});

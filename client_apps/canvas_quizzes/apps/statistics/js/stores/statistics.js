define(function(require) {
  var Store = require('canvas_quizzes/core/store');
  var config = require('../config');
  var QuizStats = require('../collections/quiz_statistics');
  var populateCollection = require('./common/populate_collection');
  var quizStats = new QuizStats([]);
  var expanded = [];

  /**
   * @class Statistics.Stores.Statistics
   * Load stats.
   */
  var store = new Store('statistics', {
    getInitialState: function() {
      return {
        loading: false
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
    load: function() {
      if (!config.quizStatisticsUrl) {
        return config.onError('Missing configuration parameter "quizStatisticsUrl".');
      }

      this.setState({ loading: true });

      return quizStats.fetch().then(function onLoad(payload) {
        this.populate(payload);
        this.setState({ loading: false });
      }.bind(this));
    },

    /**
     * Populate the store with pre-loaded statistics data you've received from
     * the Canvas stats index endpoint (JSON-API or JSON).
     *
     * @fires change
     */
    populate: function(payload) {
      populateCollection(quizStats, payload);
      this.emitChange();
    },

    get: function() {
      var props;

      if (quizStats.length) {
        props = quizStats.first().toJSON();
        props.expanded = expanded;
        props.expandingAll = this.isExpandingAll();
      }

      return props;
    },

    getExpandedSet: function() {
      return expanded;
    },

    isExpandingAll: function() {
      if (quizStats.length) {
        return expanded.length === quizStats.first().get('questionStatistics').length;
      }

      return false;
    },

    isLoading: function() {
      return this.state.loading;
    },

    getSubmissionStatistics: function() {
      var stats = this.get();
      if (stats) {
        return stats.submissionStatistics;
      }
    },

    getQuestionStatistics: function() {
      var stats = this.get();

      if (stats) {
        return stats.questionStatistics;
      }
    },

    actions: {
      expandQuestion: function(questionId, onChange) {
        if (expanded.indexOf(questionId) === -1) {
          expanded.push(questionId);
          onChange();
        }
      },

      collapseQuestion: function(questionId, onChange) {
        var index = expanded.indexOf(questionId);
        if (index !== -1) {
          expanded.splice(index, 1);
          onChange();
        }
      },

      expandAll: function(_payload, onChange) {
        if (quizStats.length) {
          expanded = quizStats.first().toJSON().questionStatistics.map(function(question) {
            return question.id;
          });

          onChange();
        }
      },

      collapseAll: function(_payload, onChange) {
        if (expanded.length) {
          expanded = [];
          onChange();
        }
      }
    },

    __reset__: function() {
      quizStats.reset();
      expandingAll = false;
      expanded = [];
      return Store.prototype.__reset__.call(this);
    }
  });

  return store;
});
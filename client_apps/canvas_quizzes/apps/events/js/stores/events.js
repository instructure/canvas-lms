define(function(require) {
  var Store = require('canvas_quizzes/core/store');
  var Environment = require('canvas_quizzes/core/environment');
  var ajax = require('canvas_quizzes/core/adapter').request;
  var Config = require('../config');
  var EventCollection = require('../collections/events');
  var QuestionCollection = require('../collections/questions');
  var Submission = require('../models/submission');
  var QuestionAnsweredEventDecorator = require('../models/question_answered_event_decorator');
  var K = require('../constants');
  var _ = require('lodash');
  var range = _.range;

  /**
   * @class Events.Stores.Events
   */
  return new Store('events', {
    getInitialState: function() {
      var attempt = Config.attempt;
      var requestedAttempt = Environment.getQueryParameter('attempt');

      if (requestedAttempt) {
        attempt = parseInt(requestedAttempt, 10);
      }

      return {
        submission: new Submission(),
        events: new EventCollection(),
        questions: new QuestionCollection(),

        loading: false,

        attempt: attempt,

        /**
         * @property {Integer} latestAttempt
         *
         * Not necessarily the current attempt of the submission we're using,
         * but instead the latest attempt available.
         *
         * @see #loadInitialData.
         */
        latestAttempt: attempt
      }
    },

    /**
     * Alright, we need to query the submission for the first time ignoring
     * any specified attempt index so that we can tell how many attempts there
     * are.
     *
     * The API does not expose that piece of information.
     *
     * This needs to be called at most once per submission during the lifetime
     * of the app.
     */
    loadInitialData: function() {
      return this.state.submission.fetch().then(function(submission) {
        var newState = {};
        var latestAttempt = this.state.submission.get('attempt');

        if (!this.state.attempt || this.state.attempt > latestAttempt) {
          newState.attempt = latestAttempt;
        }

        newState.latestAttempt = latestAttempt;

        this.setState(newState);
      }.bind(this));
    },

    load: function() {
      this.setState({ loading: true });
      this.loadSubmission()
        .then(this.loadQuestions.bind(this))
        .then(this.loadEvents.bind(this))
        .finally(function() {
          this.setState({ loading: false });
        }.bind(this));
    },

    loadSubmission: function() {
      var data;

      if (this.state.attempt) {
        data = { attempt: this.state.attempt };
      }

      return this.state.submission.fetch({ data: data });
    },

    loadQuestions: function() {
      return this.state.questions.fetchAll({
        reset: true,
        data: {
          quiz_submission_id: this.state.submission.get('id'),
          quiz_submission_attempt: this.state.attempt
        }
      });
    },

    loadEvents: function() {
      var events = this.state.events;
      var questions = this.getQuestions();

      return events.fetchAll({
        reset: true,
        data: {
          attempt: this.state.attempt,
          per_page: 50
        }
      }).then(function decorateAnswerEvents(/*payload*/) {
        var answerEvents = events.filter(function(model) {
          return model.get('type') === K.EVT_QUESTION_ANSWERED;
        });

        QuestionAnsweredEventDecorator.run(answerEvents, questions);

        return events;
      }.bind(this));
    },

    isLoading: function() {
      return this.state.loading;
    },

    getAll: function() {
      return this.state.events.toJSON();
    },

    getQuestions: function() {
      return this.state.questions.toJSON();
    },

    getSubmission: function() {
      return this.state.submission.toJSON();
    },

    getAttempt: function() {
      return this.state.attempt;
    },

    getAvailableAttempts: function() {
      return range(1, Math.max(1, (this.state.latestAttempt || 0) + 1));
    },

    setActiveAttempt: function(_attempt) {
      var attempt = parseInt(_attempt, 10);

      if (this.getAvailableAttempts().indexOf(attempt) === -1) {
        throw new Error("Invalid attempt '" + attempt + "'");
      }
      else if (this.state.attempt !== attempt) {
        this.state.attempt = attempt;
        this.load();
      }
    }
  });
});

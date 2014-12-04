define(function(require) {
  var Store = require('canvas_quizzes/core/store');
  var ajax = require('canvas_quizzes/core/adapter').request;
  var Config = require('../config');
  var EventCollection = require('../collections/events');
  var QuestionCollection = require('../collections/questions');
  var Submission = require('../models/submission');
  var _ = require('lodash');
  var range = _.range;

  /**
   * @class Events.Stores.Events
   */
  return new Store('events', {
    getInitialState: function() {
      return {
        submission: new Submission(),
        events: new EventCollection(),
        questions: new QuestionCollection(),
        cursor: null, // points to the currently selected event
        loadingQuestion: false,
        inspectedQuestionId: null,
        attempt: Config.attempt,

        /**
         * @property {Integer} latestAttempt
         *
         * Not necessarily the current attempt of the submission we're using,
         * but instead the latest attempt available.
         *
         * @see #loadInitialData.
         */
        latestAttempt: Config.attempt
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
        this.setState({ latestAttempt: this.state.submission.get('attempt') });
      }.bind(this));
    },

    load: function() {
      this.loadSubmission()
        .then(this.loadQuestions.bind(this))
        .then(this.loadEvents.bind(this))
        .then(this.emitChange.bind(this));
    },

    loadSubmission: function() {
      var data;

      if (this.state.attempt) {
        data = { attempt: this.state.attempt };
      }

      return this.state.submission.fetch({ data: data });
    },

    loadQuestions: function() {
      if (this.state.attempt === undefined) {
        this.state.attempt = this.state.submission.get('attempt');
      }

      return this.state.questions.fetchAll({
        reset: true,
        data: {
          quiz_submission_id: this.state.submission.get('id'),
          quiz_submission_attempt: this.state.attempt
        }
      });
    },

    loadEvents: function() {
      return this.state.events.fetch({
        reset: true,
        data: {
          attempt: this.state.attempt
        }
      });
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

    getInspectedQuestionId: function() {
      return this.state.inspectedQuestionId;
    },

    getInspectedQuestion: function() {
      var question = this.state.questions.get(this.state.inspectedQuestionId);

      if (question) {
        return question.toJSON();
      }
    },

    getAttempt: function() {
      return this.state.attempt;
    },

    getAvailableAttempts: function() {
      return range(1, Math.max(1, this.state.latestAttempt + 1));
    },

    isLoadingQuestion: function() {
      return !!this.state.loadingQuestion;
    },

    setCursor: function(eventId) {
      if (this.state.events.get(eventId) && this.state.cursor !== eventId) {
        this.state.cursor = eventId;
        this.emitChange();
      }
    },

    getCursor: function() {
      return this.state.cursor;
    },

    inspectQuestion: function(id) {
      var question = this.state.questions.get(id);
      var onLoad = function() {
        this.state.inspectedQuestionId = id;
        this.state.loadingQuestion = false;
        this.emitChange();
      }.bind(this);

      if (!question) {
        this.state.loadingQuestion = true;
        this.state.inspectedQuestionId = null;
        this.emitChange();

        this.loadQuestions().then(onLoad);
      }
      else {
        onLoad();
      }
    },

    stopInspectingQuestion: function() {
      if (this.state.inspectedQuestionId) {
        this.state.inspectedQuestionId = undefined;
        this.emitChange();
      }
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

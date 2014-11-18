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
        attempt: Config.attempt
      }
    },

    load: function() {
      this.state.submission.fetch()
        .then(function loadQuestions() {
          return this.state.questions.fetchAll({ reset: true });
        }.bind(this))
        .then(function ensureAttemptAndLoadEvents() {
          if (this.state.attempt === undefined) {
            this.state.attempt = this.state.submission.get('attempt');
          }

          return this.loadEvents();
        }.bind(this))
        .then(this.emitChange.bind(this));
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
      var submissionAttempt = this.state.submission.get('attempt') || 0;

      return range(1, Math.max(1, submissionAttempt+1));
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

        question = this.state.questions.push({ id: id });
        question.fetch().then(onLoad);
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
        this.loadEvents().then(this.emitChange.bind(this));
      }
    }
  });
});

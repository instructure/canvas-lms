define((require) => {
  const Store = require('canvas_quizzes/core/store');
  const Dispatcher = require('../core/dispatcher');
  const Environment = require('canvas_quizzes/core/environment');
  const Config = require('../config');
  const EventCollection = require('../collections/events');
  const QuestionCollection = require('../collections/questions');
  const Submission = require('../models/submission');
  const QuestionAnsweredEventDecorator = require('../models/question_answered_event_decorator');
  const K = require('../constants');
  const _ = require('lodash');
  const range = _.range;

  /**
   * @class Events.Stores.Events
   */
  return new Store('events', {
    getInitialState () {
      let attempt = Config.attempt;
      const requestedAttempt = Environment.getQueryParameter('attempt');

      if (requestedAttempt) {
        attempt = parseInt(requestedAttempt, 10);
      }

      return {
        submission: new Submission(),
        events: new EventCollection(),
        questions: new QuestionCollection(),

        loading: false,

        attempt,

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
    loadInitialData () {
      return this.state.submission.fetch().then((submission) => {
        const newState = {};
        const latestAttempt = this.state.submission.get('attempt');

        if (!this.state.attempt || this.state.attempt > latestAttempt) {
          newState.attempt = latestAttempt;
        }

        newState.latestAttempt = latestAttempt;

        this.setState(newState);
      });
    },

    load () {
      this.setState({ loading: true });
      this.loadSubmission()
        .then(this.loadQuestions.bind(this))
        .then(this.loadEvents.bind(this))
        .finally(() => {
          this.setState({ loading: false });
        });
    },

    loadSubmission () {
      let data;

      if (this.state.attempt) {
        data = { attempt: this.state.attempt };
      }

      return this.state.submission.fetch({ data });
    },

    loadQuestions () {
      return this.state.questions.fetchAll({
        reset: true,
        data: {
          quiz_submission_id: this.state.submission.get('id'),
          quiz_submission_attempt: this.state.attempt
        }
      });
    },

    loadEvents () {
      const events = this.state.events;
      const questions = this.getQuestions();

      return events.fetchAll({
        reset: true,
        data: {
          attempt: this.state.attempt,
          per_page: 50
        }
      }).then((/* payload*/) => {
        const answerEvents = events.filter(model => model.get('type') === K.EVT_QUESTION_ANSWERED);

        QuestionAnsweredEventDecorator.run(answerEvents, questions);

        return events;
      });
    },

    isLoading () {
      return this.state.loading;
    },

    getAll () {
      return this.state.events.toJSON();
    },

    getQuestions () {
      return this.state.questions.toJSON();
    },

    getSubmission () {
      return this.state.submission.toJSON();
    },

    getAttempt () {
      return this.state.attempt;
    },

    getAvailableAttempts () {
      return range(1, Math.max(1, (this.state.latestAttempt || 0) + 1));
    },

    setActiveAttempt (_attempt) {
      const attempt = parseInt(_attempt, 10);

      if (this.getAvailableAttempts().indexOf(attempt) === -1) {
        throw new Error(`Invalid attempt '${attempt}'`);
      } else if (this.state.attempt !== attempt) {
        this.state.attempt = attempt;
        this.load();
      }
    }
  }, Dispatcher);
});

/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_log_auditing');
  var classSet = require('canvas_quizzes/util/class_set');
  var K = require('../constants');
  var ReactRouter = require('canvas_packages/react-router');
  var Answer = require('jsx!./question_inspector/answer');
  var NoAnswer = require('jsx!./question_inspector/answers/no_answer');

  var QuestionInspector = React.createClass({
    mixins: [ ReactRouter.Navigation ],

    getDefaultProps: function() {
      return {
        question: undefined,
        events: []
      };
    },

    componentDidMount: function() {
      $('body').addClass('with-right-side');
    },

    componentWillUnmount: function() {
      $('body').removeClass('with-right-side');
    },

    render: function() {
      return(
        <div id="ic-QuizInspector__QuestionInspector">
          {this.props.question && this.renderQuestion(this.props.question)}
        </div>
      );
    },

    renderQuestion: function(question) {
      var currentEventId = this.props.currentEventId;
      var answers = [];
      this.props.events.filter(function(event) {
        return event.type === K.EVT_QUESTION_ANSWERED &&
          event.data.some(function(record) {
            return record.quizQuestionId === question.id;
          });
      }).sort(function(a,b) {
        return new Date(a.createdAt) - new Date(b.createdAt);
      }).map(function(event) {
        var records = event.data.filter(function(record) {
          return record.quizQuestionId === question.id;
        });

        records.map(function(record) {
          answers.push({
            active: event.id === currentEventId,
            value: record.answer,
            answered: record.answered
          });
        });
      });

      return (
        <div>
          <h1 className="ic-QuestionInspector__QuestionHeader">
            {I18n.t('question_header', 'Question #%{position}', {
              position: question.position
            })}

            <span className="ic-QuestionInspector__QuestionType">
              {I18n.t('question_type', '%{type}', { type: question.readableType })}
            </span>

            <span className="ic-QuestionInspector__QuestionId">
              (id: {question.id})
            </span>
          </h1>

          <div
            className="ic-QuestionInspector__QuestionText"
            dangerouslySetInnerHTML={{__html: question.questionText}} />

          <hr />

          <p>
            {I18n.t('question_response_count', {
              zero: 'This question was never answered.',
              one: 'This question was answered once.',
              other: 'This question was answered %{count} times.'
            }, { count: answers.length })}
          </p>

          <ol id="ic-QuestionInspector__Answers">
            {answers.map(this.renderAnswer)}
          </ol>
        </div>
      );
    },

    renderAnswer: function(record, index) {
      var answer;
      var className = classSet({
        'ic-QuestionInspector__Answer': true,
        'ic-QuestionInspector__Answer--is-active': !!record.active,
      });

      if (record.answered) {
        answer = Answer({
          key: "answer-"+index,
          answer: record.value,
          isActive: record.active,
          question: this.props.question
        });
      }
      else {
        answer = NoAnswer;
      }

      return (
        <li key={"answer-"+index} className={className} children={answer} />
      );
    },
  });

  return QuestionInspector;
});
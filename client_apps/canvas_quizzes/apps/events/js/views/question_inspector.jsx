/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_log_auditing');
  var Button = require('jsx!../components/button');
  var Actions = require('../actions');
  var classSet = require('canvas_quizzes/util/class_set');
  var K = require('../constants');
  var ReactRouter = require('canvas_packages/react-router');

  var NO_ANSWER = <em>{I18n.t('no_answer', 'No answer')}</em>;

  var QuestionInspector = React.createClass({
    mixins: [ ReactRouter.Navigation ],

    getDefaultProps: function() {
      return {
        loading: false,
        question: undefined
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
          {this.props.loading && <p>{I18n.t('loading', 'Loading...')}</p>}
          {this.props.question && this.renderQuestion(this.props.question)}
        </div>
      );
    },

    renderQuestion: function(question) {
      var currentEventId = this.props.currentEventId;
      var answers = this.props.events.filter(function(event) {
        return event.type === K.EVT_QUESTION_ANSWERED
          && event.data.some(function(record) {
            return record.quizQuestionId === question.id;
          });
      }).sort(function(event) {
        return event.createdAt;
      }).map(function(event) {
        return {
          active: event.id === currentEventId,
          value: event.data.filter(function(record) {
            return record.quizQuestionId === question.id;
          })[0].answer
        };
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

    renderAnswer: function(answer, index) {
      var className = classSet({
        'ic-QuestionInspector__Answer': true,
        'ic-QuestionInspector__Answer--is-active': !!answer.active,
      });

      return (
        <li key={"answer-"+index} className={className}>
          {this.getAnswerForQuestion(answer.value)}
        </li>
      );
    },

    getAnswerForQuestion: function(answer) {
      var answered = false;
      var question = this.props.question;
      var questionType = this.props.question.questionType;
      var formattedAnswer = ''+answer;
      var blank;

      switch(questionType) {
        case 'numerical_question':
        case 'multiple_choice_question':
        case 'short_answer_question':
        case 'essay_question':
          answered = answer !== null;
          break;

        case 'fill_in_multiple_blanks_question':
        case 'multiple_dropdowns_question':
          for (blank in answer) {
            if (answer.hasOwnProperty(blank)) {
              answered = answer[blank] !== null;
            }

            if (answered) {
              break;
            }
          }

          formattedAnswer = (
            <table>
              {
                Object.keys(answer).map(function(blank) {
                  return (
                    <tr>
                      <th scope="row">{blank}</th>
                      <td>{answer[blank] || NO_ANSWER}</td>
                    </tr>
                  );
                })
              }
            </table>
          );

          break;

        case 'matching_question':
          answered = answer.length > 0;

          formattedAnswer = (
            <table>
              <tr>
                <th>Left</th>
                <th>Right</th>
              </tr>

              {
                question.answers.map(function(questionAnswer) {
                  var match;
                  var answerRecord = answer.filter(function(record) {
                    return record.answer_id === questionAnswer.id+'';
                  })[0];

                  if (answerRecord) {
                    match = question.matches.filter(function(match) {
                      return (''+match.match_id) === ''+answerRecord.match_id;
                    })[0];
                  }

                  return (
                    <tr>
                      <th>{questionAnswer.left}</th>
                      <td>{match ? match.text : NO_ANSWER}</td>
                    </tr>
                  )
                })
              }
            </table>
          );
        break;

        case 'multiple_answers_question':
          answered = answer.length > 0;
        break;

        case 'file_upload_question':
          answered = answer instanceof Array && answer.length > 0;
        default:
          answered = answer !== null;
      }

      return answered ? formattedAnswer : NO_ANSWER;
    }
  });

  return QuestionInspector;
});
/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var Question = require('jsx!../question');
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var DiscriminationIndex = require('jsx!../charts/discrimination_index');
  var AnswerTable = require('jsx!./answer_table');
  var calculateResponseRatio = require('../../models/ratio_calculator');
  var QuestionHeader = require('jsx!./header');

  var ShortAnswer = React.createClass({
    render: function() {
      var props = this.props;
      var crr = calculateResponseRatio(props.answers, props.participantCount, {
        correctResponseCount: props.correct,
        questionType: props.questionType
      });

      return(
        <Question>
          <div className="grid-row">
            <div className="col-sm-8 question-top-left">
              <QuestionHeader
                responseCount={this.props.responses}
                participantCount={this.props.participantCount}
                questionText={this.props.questionText}
                position={this.props.position} />

              <div
                className="question-text"
                aria-hidden
                dangerouslySetInnerHTML={{ __html: this.props.questionText }} />
            </div>
            <div className="col-sm-4 question-top-right"></div>
          </div>
          <div className="grid-row">
            <div className="col-sm-8 question-bottom-left">
              <AnswerTable answers={this.props.answers} />
            </div>
            <div className="col-sm-4 question-bottom-right">
              <CorrectAnswerDonut correctResponseRatio={crr} />
            </div>
          </div>
        </Question>
      );
    },
  });

  return ShortAnswer;
});
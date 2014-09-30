/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var Question = require('jsx!../question');
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var AnswerBars = require('jsx!../charts/answer_bars');
  var Answers = require('jsx!./multiple_choice/answers');
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
        <Question stretched expanded={props.expanded}>
          <QuestionHeader
            responseCount={props.responses}
            participantCount={props.participantCount}
            onToggleDetails={props.onToggleDetails}
            expanded={props.expanded}
            questionText={props.questionText} />

          <div key="charts">
            <CorrectAnswerDonut correctResponseRatio={crr} />
            <AnswerBars answers={props.answers} />
          </div>

          {props.expanded && <Answers answers={props.answers} />}
        </Question>
      );
    },
  });

  return ShortAnswer;
});
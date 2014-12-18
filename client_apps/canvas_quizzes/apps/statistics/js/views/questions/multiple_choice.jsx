/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var Question = require('jsx!../question');
  var QuestionHeader = require('jsx!./header');
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var AnswerBars = require('jsx!../charts/answer_bars');
  var DiscriminationIndex = require('jsx!../charts/discrimination_index');
  var Answers = require('jsx!./multiple_choice/answers');
  var calculateResponseRatio = require('../../models/ratio_calculator');

  var MultipleChoice = React.createClass({
    render: function() {
      var rr = calculateResponseRatio(this.props.answers, this.props.participantCount, {
        questionType: this.props.questionType
      });

      return(
        <Question expanded={this.props.expanded}>
          <QuestionHeader
            responseCount={this.props.responses}
            participantCount={this.props.participantCount}
            onToggleDetails={this.props.onToggleDetails}
            expanded={this.props.expanded}
            questionText={this.props.questionText}
            position={this.props.position} />

          <div key="charts">
            <CorrectAnswerDonut correctResponseRatio={rr} />
            <AnswerBars answers={this.props.answers} />
            <DiscriminationIndex
              discriminationIndex={this.props.discriminationIndex}
              topStudentCount={this.props.topStudentCount}
              middleStudentCount={this.props.middleStudentCount}
              bottomStudentCount={this.props.bottomStudentCount}
              correctTopStudentCount={this.props.correctTopStudentCount}
              correctMiddleStudentCount={this.props.correctMiddleStudentCount}
              correctBottomStudentCount={this.props.correctBottomStudentCount}
              />
          </div>

          {this.props.expanded && <Answers answers={this.props.answers} />}
        </Question>
      );
    },
  });

  return MultipleChoice;
});
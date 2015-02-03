/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var Question = require('jsx!../question');
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var calculateResponseRatio = require('../../models/ratio_calculator');
  var QuestionHeader = require('jsx!./header');
  var I18n = require('i18n!quiz_statistics');
  var round = require('canvas_quizzes/util/round');
  var ScoreChart = require('jsx!./essay/score_chart');

  var Essay = React.createClass({
    render: function() {
      var props = this.props;
      var correctResponseRatio;

      if (props.participantCount <= 0) {
        correctResponseRatio = 0;
      }
      else {
        correctResponseRatio = props.fullCredit / props.participantCount;
      }

      return(
        <Question stretched expanded={props.expanded}>
          <QuestionHeader
            expandable={false}
            responseCount={props.responses}
            participantCount={props.participantCount}
            questionText={props.questionText}
            asideContents={this.renderAsideContent()} />

          <div key="charts">
            <CorrectAnswerDonut
              correctResponseRatio={correctResponseRatio}
              label={I18n.t('correct_essay_student_ratio',
                '%{ratio}% of your students received full credit for this question.', {
                ratio: round(correctResponseRatio * 100.0, 0)
              })} />

            <ScoreChart pointDistribution={this.props.pointDistribution} />
          </div>
        </Question>
      );
    },

    renderAsideContent: function() {
      return (
        <a href={this.props.speedGraderUrl} target="_blank">
          {I18n.t('speedgrader', 'View in SpeedGrader')}
        </a>
      );
    }
  });

  return Essay;
});
/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var I18n = require('i18n!quiz_statistics');
  var Question = require('jsx!../question');
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var AnswerBars = require('jsx!../charts/answer_bars');
  var DiscriminationIndex = require('jsx!../charts/discrimination_index');
  var Answers = require('jsx!./multiple_choice/answers');
  var ToggleDetailsButton = require('jsx!./toggle_details_button');
  var RatioCalculator = require('../../models/ratio_calculator');
  var round = require('../../util/round');

  var MultipleChoice = React.createClass({
    getInitialState: function() {
      return {
        participantCount: 0,
        correctResponseRatio: 0
      };
    },

    componentDidMount: function() {
      var calculator = new RatioCalculator(this.props.questionType, {
        answerPool: this.props.answers,
        participantCount: this.props.participantCount,
        correctResponseCount: this.props.correct,
      });

      this.setState({
        calculator: calculator,
        correctResponseRatio: calculator.getRatio()
      });
    },

    componentWillReceiveProps: function(nextProps) {
      this.updateCalculator(nextProps);
    },

    updateCalculator: function(props) {
      this.state.calculator.setAnswerPool(props.answers);
      this.state.calculator.setParticipantCount(props.participantCount);
      this.state.calculator.setCorrectResponseCount(props.correct);
      this.setState({
        correctResponseRatio: this.state.calculator.getRatio()
      });
    },

    render: function() {
      var crr = this.state.correctResponseRatio;
      var attemptsLabel = I18n.t('attempts', 'Attempts: %{count} out of %{total}', {
        count: this.props.answeredStudentCount,
        total: this.props.participantCount
      });

      var correctResponseRatioLabel = I18n.t('correct_response_ratio',
        '%{ratio}% of your students correctly answered this question.', {
        ratio: round(crr * 100.0, 0)
      });

      return(
        <Question stretched expanded={this.props.expanded}>
          <header key="header">
            <span className="question-attempts">{attemptsLabel}</span>
            <aside className="pull-right">
              <ToggleDetailsButton
                onClick={this.props.onToggleDetails}
                expanded={this.props.expanded} />
            </aside>

            <div
              className="question-text"
              dangerouslySetInnerHTML={{ __html: this.props.questionText }}
              />
          </header>

          <div key="charts">
            <section className="correct-answer-ratio-section">
              <CorrectAnswerDonut
                correctResponseRatio={this.state.correctResponseRatio}>
                <p><strong>{I18n.t('correct_answer', 'Correct answer')}</strong></p>
                <p>{correctResponseRatioLabel}</p>
              </CorrectAnswerDonut>
            </section>

            <section className="answer-distribution-section">
              <AnswerBars answers={this.props.answers} />
            </section>
          </div>

          {this.props.expanded && <Answers answers={this.props.answers} />}
        </Question>
      );
    },
  });

  return MultipleChoice;
});
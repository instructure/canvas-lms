/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_statistics');
  var Question = require('jsx!../question');
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var AnswerBars = require('jsx!../charts/answer_bars');
  var DiscriminationIndex = require('jsx!../charts/discrimination_index');
  var RatioCalculator = require('../../models/ratio_calculator');
  var round = require('../../util/round');

  var MultipleChoice = React.createClass({
    getInitialState: function() {
      return {
        participantCount: 0,
        showingDetails: false,
        correctResponseRatio: 0
      };
    },

    isShowingDetails: function() {
      return this.props.showDetails === undefined ?
        this.state.showingDetails :
        this.props.showDetails;
    },

    componentDidMount: function() {
      var calculator = new RatioCalculator(this.props.questionType, {
        answerPool: this.props.answers,
        participantCount: this.props.participantCount
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
        <Question>
          <header>
            <span className="question-attempts">{attemptsLabel}</span>
            <aside className="pull-right">
              <button onClick={this.toggleDetails} className="btn">
                {this.isShowingDetails() ?
                  <i className="icon-collapse" /> :
                  <i className="icon-expand" />
                }
              </button>
            </aside>

            <div
              className="question-text"
              dangerouslySetInnerHTML={{ __html: this.props.questionText }}
              />
          </header>

          <div>
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
            <section className="discrimination-index-section">
              <DiscriminationIndex
                discriminationIndex={this.props.discriminationIndex}
                topStudentCount={this.props.topStudentCount}
                middleStudentCount={this.props.middleStudentCount}
                bottomStudentCount={this.props.bottomStudentCount}
                correctTopStudentCount={this.props.correctTopStudentCount}
                correctMiddleStudentCount={this.props.correctMiddleStudentCount}
                correctBottomStudentCount={this.props.correctBottomStudentCount}
                />
            </section>

          </div>
        </Question>
      );
    },

    toggleDetails: function(e) {
      e.preventDefault();

      this.setState({
        showingDetails: !this.state.showingDetails
      });
    }
  });

  return MultipleChoice;
});
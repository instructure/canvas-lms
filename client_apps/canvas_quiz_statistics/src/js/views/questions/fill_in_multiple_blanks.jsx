/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var I18n = require('i18n!quiz_statistics');
  var Question = require('jsx!../question');
  var QuestionHeader = require('jsx!./header');
  var CorrectAnswerDonut = require('jsx!../charts/correct_answer_donut');
  var AnswerBars = require('jsx!../charts/answer_bars');
  var Answers = require('jsx!./multiple_choice/answers');
  var calculateResponseRatio = require('../../models/ratio_calculator');
  var round = require('../../util/round');
  var classSet = require('../../util/class_set');

  var FillInMultipleBlanks = React.createClass({
    getInitialState: function() {
      return {
        answerSetId: undefined,
      };
    },

    getDefaultProps: function() {
      return {
        answerSets: []
      };
    },

    getAnswerPool: function() {
      var answerSets = this.props.answerSets;
      var answerSetId = this.state.answerSetId || (answerSets[0] || {}).id;
      var answerSet = answerSets.filter(function(answerSet) {
        return answerSet.id === answerSetId;
      })[0] || { answers: [] };

      return answerSet.answers;
    },

    componentDidMount: function() {
      // Make sure we always have an active answer set:
      this.ensureAnswerSetSelection(this.props);
    },

    componentWillReceiveProps: function(nextProps) {
      this.ensureAnswerSetSelection(nextProps);
    },

    render: function() {
      var crr = calculateResponseRatio(this.getAnswerPool(), this.props.participantCount, {
        questionType: this.props.questionType
      });
      var answerPool = this.getAnswerPool();

      return(
        <Question expanded={this.props.expanded}>
          <QuestionHeader
            responseCount={this.props.responses}
            participantCount={this.props.participantCount}
            onToggleDetails={this.props.onToggleDetails}
            expanded={this.props.expanded}
            questionText={this.props.questionText}
            position={this.props.position} />

          <nav className="row-fluid answer-set-tabs">
            {this.props.answerSets.map(this.renderAnswerSetTab)}
          </nav>

          <div key="charts">
            <CorrectAnswerDonut
              correctResponseRatio={crr}
              label={I18n.t('correct_multiple_response_ratio',
                '%{ratio}% of your students responded correctly.', {
                ratio: round(crr * 100.0, 0)
              })} />

            <AnswerBars answers={answerPool} />
          </div>

          {this.props.expanded && <Answers answers={answerPool} />}
        </Question>
      );
    },

    renderAnswerSetTab: function(answerSet) {
      var id = answerSet.id;
      var className = classSet({
        'active': this.state.answerSetId === id
      });

      return (
        <button
          key={'answerSet-' + id}
          onClick={this.switchAnswerSet.bind(null, id)}
          className={className}
          children={answerSet.text} />
      );
    },

    ensureAnswerSetSelection: function(props) {
      if (!this.state.answerSetId && props.answerSets.length) {
        this.setState({ answerSetId: props.answerSets[0].id });
      }
    },

    switchAnswerSet: function(answerSetId, e) {
      e.preventDefault();

      this.setState({
        answerSetId: answerSetId
      });
    }
  });

  return FillInMultipleBlanks;
});
/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var _ = require('lodash');
  var ChartMixin = require('../../mixins/chart');
  var ChartInspectorMixin = require('../../mixins/components/chart_inspector');
  var I18n = require('i18n!quiz_statistics.answer_bars_chart');
  var ScreenReaderContent = require('jsx!../../components/screen_reader_content');
  var Text = require('jsx!../../components/text');
  var round = require('../../util/round');
  var Chart = require('jsx!./answer_bars/chart');
  var Table = require('jsx!./answer_bars/table');

  var AnswerBars = React.createClass({
    propTypes: {
    },

    getDefaultProps: function() {
      return {
        answers: [],
        children: []
      };
    },

    render: function() {
      var chartData = this.props.answers.map(function(answer) {
        return {
          id: ''+answer.id,
          y: answer.responses,
          correct: answer.correct
        };
      });

      var tableData = this.props.answers.map(function(answer) {
        return {
          id: answer.id,
          text: answer.text,
          correct: answer.correct,
          responses: answer.responses
        }
      });

      return (
        <section className="answer-distribution-section">
          <Chart ref="chart" answers={chartData} onInspect={this.getAnswerTooltip} />
          <ScreenReaderContent tagName="div">
            <Table answers={tableData} />
          </ScreenReaderContent>

          <div className="auxiliary" style={{display:'none'}}>
            {this.props.answers.map(this.renderAnswerTooltip)}
          </div>
        </section>
      );
    },

    renderAnswerTooltip: function(answer) {
      return (
        <div
          key={'answer-' + answer.id}
          ref={'answer_' + answer.id}
          className="answer-distribution-tooltip-content">
          <p>
            <span className="answer-response-ratio">{round(answer.ratio)}%</span>
            <span className="answer-response-count">
              {I18n.t('response_count', {
                zero: 'Nobody',
                one: '1 student',
                other: '%{count} students'
              }, { count: answer.responses })}
            </span>
          </p>

          <hr />

          <div className="answer-text">
            {answer.text}
          </div>
        </div>
      );
    },

    getAnswerTooltip: function(answerId) {
      return this.refs['answer_' + answerId].getDOMNode();
    }
  });

  return AnswerBars;
});

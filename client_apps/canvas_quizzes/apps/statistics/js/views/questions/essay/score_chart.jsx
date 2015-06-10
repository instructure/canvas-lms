/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var _ = require('lodash');
  var ChartMixin = require('../../../mixins/chart');
  var ChartInspectorMixin = require('../../../mixins/components/chart_inspector');
  var I18n = require('i18n!quiz_statistics');
  var round = require('canvas_quizzes/util/round');

  var Chart = React.createClass({
    mixins: [ ChartMixin.mixin, ChartInspectorMixin.mixin ],

    tooltipOptions: {
      position: {
        my: 'center+15 bottom',
        at: 'center top-8'
      }
    },

    getDefaultProps: function() {
      return {
        answers: [],

        /**
         * @property {Number} [barWidth=30]
         * Width of the bars in the chart in pixels.
         */
        barWidth: 30,

        /**
         * @property {Number} [barMargin=1]
         *
         * Whitespace to offset the bars by, in pixels.
         */
        barMargin: 1,
        xOffset: 16,
        yAxisLabel: '',
        xAxisLabels: false,
        linearScale: true,
        width: 'auto',
        height: 120
      };
    },

    createChart: function(node, props) {
      var line, area;
      var data = props.scores;
      var container = this.getDOMNode();

      var radius = 4;
      var circleVisibilityThreshold = radius * 4;
      var margin = {
        left: circleVisibilityThreshold,
        top: circleVisibilityThreshold,
        right: circleVisibilityThreshold,
        bottom: 0
      };

      var width = 580 - margin.left - margin.right;
      var height = 120 - margin.top - margin.bottom;

      var x = d3.scale.linear().range([0, width]);
      var y = d3.scale.linear().range([height, 0]);

      var svg = d3.select(node)
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
          .attr('transform', "translate(" + margin.left + "," + margin.top + ")");

      x.domain(d3.extent(data, function(d) { return d.score; }));
      y.domain([ 0, d3.max(data, function(d) { return d.count; })]);

      line = d3.svg.line()
        .x(function(d) { return x(d.score); })
        .y(function(d) { return y(d.count); });

      area = d3.svg.area()
        .x(function(d) { return x(d.score); })
        .y0(height)
        .y1(function(d) { return y(d.count); });

      svg.selectAll('path.score-line')
        .data(data).enter()
        .append('path')
          .attr('class', 'score-line')
          .attr('d', line(data));

      svg.append('path').datum(data)
        .attr('class', 'area')
        .attr('d', area);

      var circles = svg.selectAll('circle')
        .data(data).enter()
        .append('circle')
          .attr('cx', function(d) { return x(d.score); })
          .attr('cy', function(d) { return y(d.count) - radius; })
          .attr('r', radius * 2);

      ChartInspectorMixin.makeInspectable(circles, this);

      return svg;
    },

    updateChart: ChartMixin.mixin.updateChart,
    removeChart: ChartMixin.mixin.removeChart,

    render: function() {
      return (
        <div>
          <div ref="inspector" />
          <svg ref="chart" className="chart" />
        </div>
      );
    }
  });

  var ScoreDistribution = React.createClass({
    propTypes: {
    },

    getDefaultProps: function() {
      return {
        pointDistribution: []
      };
    },

    render: function() {
      var chartData = this.props.pointDistribution.map(function(point) {
        return {
          id: ''+point.score,
          score: point.score,
          count: point.count
        };
      });

      return (
        <section className="essay-score-chart-section">
          <Chart ref="chart" scores={chartData} onInspect={this.getAnswerTooltip} />

          <div className="auxiliary" style={{display:'none'}}>
            {this.props.pointDistribution.map(this.renderAnswerTooltip)}
          </div>
        </section>
      );
    },

    renderAnswerTooltip: function(point) {
      return (
        <div
          key={'point-' + point.score + '-' + point.count}
          ref={'point_' + point.score + '_' + point.count}
          className="answer-distribution-tooltip-content">
          <p>
            <span className="answer-response-ratio">{round(point.ratio)}%</span>
            <span className="answer-response-count">
              {I18n.t('response_student_count', {
                zero: 'Nobody',
                one: '1 student',
                other: '%{count} students'
              }, { count: point.count })}
            </span>
          </p>

          <hr />

          <div className="answer-text">
            {I18n.t('essay_score', 'Score: %{score}', { score: point.score })}
          </div>
        </div>
      );
    },

    getAnswerTooltip: function(__answerId, point) {
      return this.refs['point_' + point.score + '_' + point.count].getDOMNode();
    }
  });

  return ScoreDistribution;
});
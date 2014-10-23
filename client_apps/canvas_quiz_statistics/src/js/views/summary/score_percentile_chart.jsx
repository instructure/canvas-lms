/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ChartMixin = require('../../mixins/chart');
  var d3 = require('d3');
  var I18n = require('i18n!quiz_statistics.summary');
  var max = d3.max;
  var sum = d3.sum;

  var MARGIN_T = 0;
  var MARGIN_R = 0;
  var MARGIN_B = 40;
  var MARGIN_L = -40;
  var WIDTH = 960;
  var HEIGHT = 220;
  var BAR_WIDTH = 10;
  var BAR_MARGIN = 0.25;

  var ScorePercentileChart = React.createClass({
    mixins: [ ChartMixin.mixin ],

    propTypes: {
      scores: React.PropTypes.object.isRequired,
      scoreAverage: React.PropTypes.number.isRequired,
      pointsPossible: React.PropTypes.number.isRequired,
    },

    getDefaultProps: function() {
      return {
        scores: {}
      };
    },

    createChart: function(node, props) {
      var svg, width, height, x, y, xAxis;
      var highest;
      var visibilityThreshold;
      var data = this.chartData(props);
      var avgScore = props.scoreAverage / props.pointsPossible * 100.0;
      var labelOptions = this.calculateStudentStatistics(avgScore, data);

      width = WIDTH - MARGIN_L - MARGIN_R;
      height = HEIGHT - MARGIN_T - MARGIN_B;
      highest = max(data);

      x = d3.scale.ordinal().rangeRoundBands([0, BAR_WIDTH * data.length], BAR_MARGIN);
      y = d3.scale.linear().range([0, highest]).rangeRound([height, 0]);

      x.domain(data.map(function(d, i) {
        return i;
      }));

      y.domain([0, highest]);

      xAxis = d3.svg.axis().scale(x).orient("bottom").tickValues(d3.range(0, 101, 10)).tickFormat(function(d) {
        return d + '%';
      });

      svg = d3.select(node)
        .attr('role', 'document')
        .attr('aria-role', 'document')
        .attr('width', width + MARGIN_L + MARGIN_R)
        .attr('height', height + MARGIN_T + MARGIN_B)
        .attr('viewBox', "0 0 " + (width + MARGIN_L + MARGIN_R) + " " + (height + MARGIN_T + MARGIN_B))
        .attr('preserveAspectRatio', 'xMinYMax')
          .append('g')
          .attr('transform', "translate(" + MARGIN_L + "," + MARGIN_T + ")")

      ChartMixin.addTitle(svg, I18n.t('chart_title', 'Score percentiles chart'));
      ChartMixin.addDescription(svg, I18n.t('audible_chart_description',
      '%{above_average} students scored above or at the average, and %{below_average} below.', {
        above_average: labelOptions.aboveAverage,
        below_average: labelOptions.belowAverage
      }));

      svg.append('g')
        .attr('class', 'x axis')
        .attr('aria-hidden', true)
        .attr('transform', "translate(0," + height + ")")
        .call(xAxis);

      visibilityThreshold = Math.min(highest / 100, 0.5);

      svg.selectAll('rect.bar')
        .data(data)
        .enter()
          .append('rect')
            .attr("class", 'bar')
            .attr('x', function(d, i) {
              return x(i);
            }).attr('width', x.rangeBand).attr('y', function(d) {
              return y(d + visibilityThreshold);
            }).attr('height', function(d) {
              return height - y(d + visibilityThreshold);
            });

      return svg;
    },

    /**
     * Calculate the number of students who scored above, or at, the average
     * and those who did lower.
     *
     * @param  {Number} _avgScore
     * @param  {Number[]} scores
     *         The flattened score percentile data-set (see #chartData()).
     *
     * @return {Object} out
     * @return {Number} out.aboveAverage
     * @return {Number} out.belowAverage
     */
    calculateStudentStatistics: function(_avgScore, scores) {
      var avgScore = Math.round(_avgScore);

      return {
        aboveAverage: scores.filter(function(__y, percentile) {
          return percentile >= avgScore;
        }).reduce(function(count, y) {
          return count + y;
        }, 0),

        belowAverage: scores.filter(function(__y, percentile) {
          return percentile < avgScore;
        }).reduce(function(count, y) {
          return count + y;
        }, 0)
      };
    },

    chartData: function(props) {
      var percentile, upperBound;
      var set = [];
      var scores = props.scores || {};
      var highest = max(Object.keys(scores).map(function(score) {
        return parseInt(score, 10);
      }));

      upperBound = max([101, highest]);

      for (percentile = 0; percentile < upperBound; ++percentile) {
        set[percentile] = scores[''+percentile] || 0;
      }

      // merge right outliers with 100%
      set[100] = sum(set.splice(100, set.length));

      return set;
    },

    render: ChartMixin.defaults.render
  });

  return ScorePercentileChart;
});
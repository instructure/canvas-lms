/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ChartMixin = require('../mixins/chart');
  var d3 = require('d3');
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
      scores: React.PropTypes.object.isRequired
    },

    getDefaultProps: function() {
      return {
        scores: {}
      };
    },

    createChart: function(node, props) {
      var height, highest, svg, width, x, xAxis, y;
      var data = this.chartData(props);

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
        .attr('width', width + MARGIN_L + MARGIN_R)
        .attr('height', height + MARGIN_T + MARGIN_B)
        .attr('viewBox', "0 0 " + (width + MARGIN_L + MARGIN_R) + " " + (height + MARGIN_T + MARGIN_B))
        .attr('preserveAspectRatio', 'xMinYMax')
          .append('g')
          .attr("transform", "translate(" + MARGIN_L + "," + MARGIN_T + ")");

      svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', "translate(0," + height + ")")
        .call(xAxis);

      this.renderPercentileChart(svg, data, x, y, height);

      return svg;
    },

    renderPercentileChart: function(svg, data, x, y, height) {
      var highest, visibilityThreshold;

      highest = y.domain()[1];

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
    },

    chartData: function(props) {
      var percentile, upperBound;
      var set = [];
      var scores = props.scores || {};
      var highest = max(Object.keys(scores).map(function(score) {
        return parseInt(score, 10);
      }));

      upperBound = max([100, highest]);

      for (percentile = 0; percentile < upperBound; ++percentile) {
        set[percentile] = scores[''+percentile] || 0;
      }

      // merge right outliers with 100%
      set[100] = sum(set.splice(100, set.length));

      return set;
    }
  });

  return ScorePercentileChart;
});
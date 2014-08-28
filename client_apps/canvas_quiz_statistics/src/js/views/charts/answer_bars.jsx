/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var _ = require('lodash');
  var ChartMixin = require('../../mixins/chart');

  var mapBy = _.map;
  var findWhere = _.findWhere;
  var compact = _.compact;

  var Chart = React.createClass({
    mixins: [ ChartMixin.mixin ],
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
      var otherAnswers;
      var data = props.answers;
      var container = this.getDOMNode();

      var sz = data.reduce(function(sum, item) {
        return sum + item.y;
      }, 0);

      var highest = d3.max(mapBy(data, 'y'));

      var width, height;
      var margin = { top: 0, right: 0, bottom: 0, left: 0 };

      if (props.width === 'auto') {
        width = container.offsetWidth;
      }
      else {
        width = parseInt(props.width, 10);
      }

      width -= margin.left - margin.right;
      height = props.height - margin.top - margin.bottom;

      var barWidth = props.barWidth;
      var barMargin = props.barMargin;
      var xOffset = props.xOffset;

      var x = d3.scale.ordinal()
        .rangeRoundBands([0, barWidth * sz], 0.025);

      var y = d3.scale.linear()
        .range([height, 0]);

      var visibilityThreshold = Math.max(5, y(highest) / 100.0);

      var svg = d3.select(node)
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
          .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

      var classifyChartBar = this.classifyChartBar;

      x.domain(data.map(function(d, i) { return d.label || i; }));
      y.domain([ 0, sz ]);

      svg.selectAll('.bar')
        .data(data)
        .enter().append('rect')
          .attr("class", function(d) {
            return classifyChartBar(d);
          })
          .attr("x", function(d, i) {
            return i * (barWidth + barMargin) + xOffset;
          })
          .attr("width", barWidth)
          .attr("y", function(d) {
            return y(d.y) - visibilityThreshold;
          })
          .attr("height", function(d) {
            return height - y(d.y) + visibilityThreshold;
          });

      // If the special "No Answer" is present, we represent it as a diagonally-
      // striped bar, but to do that we need to render the <svg:pattern> that
      // generates the stripes and use that as a fill pattern, and we also need
      // to create the <svg:rect> that will be filled with that pattern.
      otherAnswers = compact([
        findWhere(data, { id: 'other' }),
        findWhere(data, { id: 'none' })
      ]);

      if (otherAnswers.length) {
        this.renderStripePattern(svg);
        svg.selectAll('.bar.bar-striped')
          .data(otherAnswers)
          .enter().append('rect')
            .attr('class', 'bar bar-striped')
            // We need to inline the fill style because we are referencing an
            // inline pattern (#diagonalStripes) which is unreachable from a CSS
            // directive.
            //
            // See this link [StackOverflow] for more info: http://bit.ly/1uDTqyn
            .attr('style', 'fill: url(#diagonalStripes);')
            // remove 2 pixels from width and height, and offset it by {1,1} on
            // both axes to "contain" it inside the margins of the bg rect
            .attr('x', function(d) {
              return data.indexOf(d) * (barWidth + barMargin) + xOffset + 1;
            })
            .attr('width', barWidth-2)
            .attr('y', function(d) {
              return y(d.y + visibilityThreshold) + 1;
            })
            .attr('height', function(d) {
              return height - y(d.y + visibilityThreshold) - 2;
            });
      }

      return svg;
    },

    renderStripePattern: function(svg) {
      svg.append('pattern')
        .attr('id', 'diagonalStripes')
        .attr('width', 5)
        .attr('height', 5)
        .attr('patternTransform', 'rotate(45 0 0)')
        .attr('patternUnits', 'userSpaceOnUse')
        .append('g')
          .append('path')
            .attr('d', 'M0,0 L0,10');
    },

    classifyChartBar: function(answer) {
      if (answer.correct) {
        return 'bar bar-highlighted';
      } else {
        return 'bar';
      }
    }
  });

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

      return (
        <div>
          <Chart answers={chartData} />

          <div className="auxiliary">
            {this.props.children}
          </div>
        </div>
      );
    }
  });

  return AnswerBars;
});
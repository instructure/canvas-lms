/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var _ = require('lodash');
  var ChartMixin = require('../../../mixins/chart');
  var ChartInspectorMixin = require('../../../mixins/components/chart_inspector');

  var mapBy = _.map;
  var findWhere = _.findWhere;
  var compact = _.compact;

  var SPECIAL_DATUM_IDS = [ 'other', 'none' ];

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
         *
         * Prefered width of the bars in pixels. This value will be respected
         * only if the chart's container is wide enough to contain all the
         * bars with that specified value.
         */
        barWidth: 30,

        /**
         * @property {Number} [padding=0.05]
         *
         * An amount of whitespace/padding to render between each pair of bars.
         * Value is in the range of [0,1] and represents a percentage of the
         * bar's *calculated* width.
         *
         * So, a padding of 0.5 means a number of pixels equal to half the bar's
         * width will be rendered as whitespace.
         */
        padding: 0.05,

        /**
         * @property {Number} [visibilityThreshold=5]
         *
         * An amount of pixels to use for a bar's height in the special case
         * where an answer has received no responses (e.g, y=0).
         *
         * Setting this to a positive number would show the bar for such answers
         * so that the tooltip can be triggered.
         */
        visibilityThreshold: 5,

        /**
         * @property {String|Number} [width="auto"]
         *
         * Width of the chart in pixels. If set to "auto", the width will be
         * equal to that of the element containing the chart.
         */
        width: 'auto',

        height: 120,

        animeDuration: 500
      };
    },

    createChart: function(node, props) {
      var width = this.calculateWidth(props);
      var svg = d3.select(node)
        .attr('width', width)
        .attr('height', props.height)
        .attr('aria-hidden', true)
        .attr('role', 'presentation')
        .append('g');

      this.renderBars(svg, props);
      this.renderStripePattern(svg);

      return svg;
    },

    calculateWidth: function(props) {
      if (props.width === 'auto') {
        return this.getDOMNode().offsetWidth;
      }
      else {
        return parseInt(props.width, 10);
      }
    },

    updateChart: function(svg, props) {
      this.renderBars(svg, props);
    },

    renderBars: function(svg, props) {
      var visibilityThreshold;
      var specialAnswers;
      var width = this.calculateWidth(props);
      var data = props.answers;
      var barCount = data.length;

      // The highest response count, for defining the y-axis range boundaries.
      var highest = d3.max(mapBy(data, 'y'));

      // Uniform width of the bars that will represent answer sets. This amount
      // will consider @props.barWidth only if the chart is large enough to
      // accommodate all the bars with the requested width. Otherwise, we'll
      // use the largest width possible that satisfies rendering *all* the
      // answer sets.
      //
      // Also, a reasonable amount of padding will be rendered between each pair
      // of bars that is equal to a 1/4 of a bar's calculated width.
      var effectiveBarWidth;

      // Scales for the x and y axes.
      var x, y;
      var xUpperBound;
      var bars, stripedBars;

      // Need to figure out the upper boundary of the range for the x axis scale;
      // if the container is wide enough to display all the answer bars with the
      // requested width, we'll clamp the viewport width to be narrow enough to
      // just fit so that the bars are not widely spaced out. Otherwise, we use
      // the entire viewport.
      if (props.barWidth * barCount <= width) {
        xUpperBound = props.barWidth * barCount;
      }
      else {
        xUpperBound = width;
      }

      x = d3.scale.ordinal()
        .domain(d3.range(barCount))
        .rangeRoundBands([ 0, xUpperBound ], props.padding, 0 /* edge padding */);

      effectiveBarWidth = d3.min([ x.rangeBand(), props.barWidth ]);

      y = d3.scale.linear()
        .domain([ 0, highest ])
        .range([ props.height, 0 ]);

      visibilityThreshold = Math.max(props.visibilityThreshold, y(highest) / 100.0);

      bars = svg.selectAll('.bar')
        .data(data, function(d, i) { return d.id; });

      bars.enter().append('rect')
        .attr("class", function(d) {
          return d.correct ? 'bar bar-highlighted' : 'bar';
        })
        .attr("x", function(d, i) {
          return x(i);
        })
        .attr('y', props.height)
        .attr("width", effectiveBarWidth)
        .attr('height', 0);

      bars.transition()
        .duration(props.animeDuration)
        .attr("y", function(d) {
          return y(d.y) - visibilityThreshold;
        })
        .attr("height", function(d) {
          return props.height - y(d.y) + visibilityThreshold;
        });

      bars.exit().remove();

      // If the special "No Answer" is present, we represent it as a diagonally-
      // striped bar, but to do that we need to render the <svg:pattern> that
      // generates the stripes and use that as a fill pattern, and we also need
      // to create the <svg:rect> that will be filled with that pattern.
      specialAnswers = data.filter(function(d) {
        return SPECIAL_DATUM_IDS.indexOf(d.id) > -1;
      });

      stripedBars = svg.selectAll('.bar-striped')
        .data(specialAnswers, function(d) { return d.id; });

      stripedBars.enter().append('rect')
        .attr('class', 'bar-striped')
        // We need to inline the fill style because we are referencing an
        // inline pattern (#diagonalStripes) which is unreachable from a CSS
        // directive.
        //
        // See this link [StackOverflow] for more info: http://bit.ly/1uDTqyn
        .style('fill', 'url(#diagonalStripes)')
        // remove 2 pixels from width and height, and offset it by {1,1} on
        // both axes to "contain" it inside the margins of the bg rect
        .attr('x', function(d) {
          var i = data.indexOf(d); // d is coming from specialAnswers
          return x(i) + 1;
        })
        .attr('width', effectiveBarWidth-2)
        .attr("y", props.height)
        .attr('height', 0);

      stripedBars.transition()
        .duration(props.animeDuration)
        .attr("y", function(d) {
          return y(d.y) - visibilityThreshold + 1;
        })
        .attr("height", function(d) {
          return props.height - y(d.y) + visibilityThreshold - 2;
        });

      stripedBars.exit().remove();

      ChartInspectorMixin.makeInspectable(svg.selectAll('.bar, .bar-striped'), this);
    },

    renderStripePattern: function(svg) {
      svg.append('pattern')
        // we must assign an ID even if it will violate the uniqueness (other
        // instances will render exactly the same pattern with this ID) because
        // the inline referencing only works with IDs AND it must be reachable
        // from the root svg element... so we can't share 1 instance in <body />
        // or something
        .attr('id', 'diagonalStripes')
        .attr('width', 5)
        .attr('height', 5)
        .attr('patternTransform', 'rotate(45 0 0)')
        .attr('patternUnits', 'userSpaceOnUse')
        .append('g')
          .append('path')
            .attr('d', 'M0,0 L0,10');
    },

    removeChart: ChartMixin.mixin.removeChart,

    render: function() {
      return (
        <div>
          <div ref="inspector" />
          <svg ref="chart" className="chart"></svg>
        </div>
      );
    }
  });

  return Chart;
});
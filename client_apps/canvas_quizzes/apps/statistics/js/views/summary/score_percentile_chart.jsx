/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var ChartMixin = require('../../mixins/chart');
  var d3 = require('d3');
  var _ = require('lodash');
  var I18n = require('i18n!quiz_statistics.summary');
  var max = d3.max;
  var sum = d3.sum;
  var throttle = _.throttle;

  var MARGIN_T = 0;
  var MARGIN_R = 18;
  var MARGIN_B = 60;
  var MARGIN_L = 34;
  var CHART_BRUSHING_TIP_LABEL = I18n.t(
    'chart_brushing_tip',
    'Tip: you can focus a specific segment of the chart by making a ' +
    'selection using your cursor.'
  );

  var ScorePercentileChart = React.createClass({
    mixins: [ ChartMixin.mixin ],

    propTypes: {
      scores: React.PropTypes.object,
      scoreAverage: React.PropTypes.number,
      pointsPossible: React.PropTypes.number,
    },

    getDefaultProps: function() {
      return {
        scores: {},
        animeDelay: 500,
        animeDuration: 500,
        width: 960,
        height: 220,
        barPadding: 0.25,
        minBarHeight: 1
      };
    },

    createChart: function(node, props) {
      var svg, width, height, x, xAxis;
      var brush, brushCaption, onBrushed;
      var barContainer;

      width = props.width - MARGIN_L - MARGIN_R;
      height = props.height - MARGIN_T - MARGIN_B;

      // the x scale is static since it will always represent the 100
      // percentiles, so we can avoid recalculating it on every update:
      x = d3.scale.ordinal().rangeRoundBands([0, width], props.barPadding, 0);
      x.domain(d3.range(0, 101, 1));

      xAxis = d3.svg.axis()
        .scale(x)
        .orient("bottom")
        .tickValues(d3.range(0, 101, 10))
        .tickFormat(function(d) { return d + '%'; });

      svg = d3.select(node)
        .attr('role', 'document')
        .attr('aria-role', 'document')
        .attr('width', width + MARGIN_L + MARGIN_R)
        .attr('height', height + MARGIN_T + MARGIN_B)
        .attr('viewBox', "0 0 " + (width + MARGIN_L + MARGIN_R) + " " + (height + MARGIN_T + MARGIN_B))
        .attr('preserveAspectRatio', 'xMidYMax')
          .append('g');

      this.title = ChartMixin.addTitle(svg, '');
      this.description = ChartMixin.addDescription(svg, '');

      svg.append('g')
        .attr('class', 'x axis')
        .attr('aria-hidden', true)
        .attr('transform', "translate(5," + height + ")")
        .call(xAxis);

      barContainer = svg.append('g');

      brushCaption = svg
        .append('text')
        .attr('class', 'brush-stats unused')
        .attr('text-anchor', 'left')
        .attr('aria-hidden', true)
        .attr('dy', '.35em')
        .attr('y', height + 40)
        .attr('x', 0)
        .text(CHART_BRUSHING_TIP_LABEL);

      onBrushed = throttle(this.onBrushed, 100, {
        leading: false,
        trailing: true
      });

      brush = d3.svg.brush()
        .x(x)
        .clamp(true)
        .on("brush", onBrushed);

      this.brushContainer = svg.append("g")
        .attr("class", "x brush")
        .call(brush);

      this.brushContainer.selectAll("rect")
        .attr("y", props.minBarHeight)
        .attr("height", height + props.minBarHeight);

      this.x = x;
      this.height = height;
      this.barContainer = barContainer;
      this.brushCaption = brushCaption;
      this.brush = brush;

      this.updateChart(svg, props);

      return svg;
    },

    updateChart: function(svg, props) {
      var labelOptions;
      var data = this.chartData = this.calculateChartData(props);
      var avgScore = props.scoreAverage / props.pointsPossible * 100.0;
      labelOptions = this.calculateStudentStatistics(avgScore, data);

      this.title.text(I18n.t('chart_title', 'Score percentiles chart'));
      this.description.text(I18n.t('audible_chart_description',
      '%{above_average} students scored above or at the average, and %{below_average} below.', {
        above_average: labelOptions.aboveAverage,
        below_average: labelOptions.belowAverage
      }));

      this.renderBars(this.barContainer, props);

      if (!this.brush.empty()) {
        this.onBrushed();
      }
    },

    renderBars: function(svg, props) {
      var height, x, y, bars;
      var highest;
      var visibilityThreshold;
      var data = this.chartData;

      height = this.height;
      highest = max(data);

      x = this.x;

      y = d3.scale.linear()
        .range([0, highest])
        .rangeRound([height, 0]);

      y.domain([0, highest]);

      visibilityThreshold = Math.max(highest / 100, props.minBarHeight);

      bars = svg.selectAll('rect.bar').data(data);

      bars.enter()
        .append('rect')
          .attr("class", 'bar')
          .attr('x', function(d, i) { return x(i); })
          .attr('y', height)
          .attr('width', x.rangeBand)
          .attr('height', 0);

      bars.transition()
        .delay(props.animeDelay)
        .duration(props.animeDuration)
        .attr('y', function(d) { return y(d) + visibilityThreshold; })
        .attr('height', function(d) {
          return height - y(d) + visibilityThreshold;
        });

      bars.exit().remove();
    },

    /**
     * @private
     *
     * Calculate the number of students who scored above, or at, the average
     * and those who did lower.
     *
     * @param  {Number} _avgScore
     * @param  {Number[]} scores
     *         The flattened score percentile data-set (see #calculateChartData()).
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

    /**
     * @private
     */
    calculateChartData: function(props) {
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

    /**
     * @private
     *
     * Update the focus caption with the number of students who are allocated to
     * the "brushed" percentile range (which could be just a single point as
     * well).
     */
    onBrushed: function() {
      var i, a, b;
      var studentCount;
      var message;

      var brush = this.brush;
      var brushCaption = this.brushCaption;
      var data = this.chartData;

      var range = this.x.range();
      var extent = brush.extent();

      // invert the brush extent against the X scale and locate the percentiles
      // we're focusing, a and b:
      for (i = 0; i < range.length; ++i) {
        if (a === undefined && range[i] > extent[0]) {
          a = Math.max(i-1, 0);
        }

        if (b === undefined && range[i] > extent[1]) {
          b = Math.max(i-1, 0);
        }

        if (a !== undefined && b !== undefined) {
          break;
        }
      }

      // if at this point we still didn't find the end percentile, it means
      // the brush extends beyond the last percentile (100%) so just choose that
      if (b === undefined) {
        b = range.length - 1;

        if (a === undefined) { // single-point brush
          a = b;
        }
      }

      if (a - b === 0) { // single percentile
        studentCount = data[a] || 0;

        message = I18n.t('students_who_got_a_certain_score', {
          zero: 'No students have received a score of %{score}%.',
          one: 'One student has received a score of %{score}%.',
          other: '%{count} students have received a score of %{score}%.',
        }, {
          count: studentCount,
          score: a
        });

        // redraw the brush to cover the percentile bar:
        this.brush.extent([ range[a], range[b] + this.x.rangeBand() ]);
        this.brush(this.brushContainer);
      }
      else { // percentile range
        studentCount = 0;

        for (i = a; i <= b; ++i) {
          studentCount += data[i] || 0;
        }

        message = I18n.t('students_who_scored_in_a_range', {
          zero: 'No students have scored between %{start} and %{end}%.',
          one: 'One student has scored between %{start} and %{end}%.',
          other: '%{count} students have scored between %{start} and %{end}%.',
        }, {
          count: studentCount,
          start: a,
          end: b
        });
      }

      brushCaption.text(message).attr('class', 'brush-stats');
    },

    render: ChartMixin.defaults.render
  });

  return ScorePercentileChart;
});
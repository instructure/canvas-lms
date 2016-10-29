/** @jsx React.DOM */
define(function(require) {
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var ChartMixin = require('../../mixins/chart');
  var d3 = require('d3');
  var I18n = require('i18n!quiz_statistics.summary');
  var max = d3.max;
  var sum = d3.sum;

  var MARGIN_T = 0;
  var MARGIN_R = 18;
  var MARGIN_B = 60;
  var MARGIN_L = 34;

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
        minBarHeight: 1,
        numTicks: 5
      };
    },

    createChart: function(node, props) {
      var svg, width, height, x, xAxis;
      var barContainer;

      width = props.width - MARGIN_L - MARGIN_R;
      height = props.height - MARGIN_T - MARGIN_B;

      // the x scale is static since it will always represent the 100
      // percentiles, so we can avoid recalculating it on every update:
      x = d3.scale.ordinal().rangeRoundBands([0, width], props.barPadding, 0);
      x.domain(d3.range(0, 101, 1));

      this.y = d3.scale.linear().range([height, 0]);

      xAxis = d3.svg.axis()
        .scale(x)
        .orient("bottom")
        .tickValues(d3.range(0, 101, 10))
        .tickFormat(function(d) { return d + '%'; });

      this.yAxis = d3.svg.axis()
        .scale(this.y)
        .orient("left")
        .outerTickSize(0)
        .ticks(props.numTicks);

      svg = d3.select(node)
        .attr('role', 'document')
        .attr('aria-role', 'document')
        .attr('width', width + MARGIN_L + MARGIN_R)
        .attr('height', height + MARGIN_T + MARGIN_B)
        .attr('viewBox', "0 0 " + (width + MARGIN_L + MARGIN_R) + " " + (height + MARGIN_T + MARGIN_B))
        .attr('preserveAspectRatio', 'xMidYMax')
          .append('g');

      this.title = ChartMixin.addTitle(svg, '');

      const descriptionHolder = (this.refs.wrapper && d3.select(this.refs.wrapper.getDOMNode())) || svg
      this.description = ChartMixin.addDescription(descriptionHolder, '');

      svg.append('g')
        .attr('class', 'x axis')
        .attr('aria-hidden', true)
        .attr('transform', "translate(5," + height + ")")
        .call(xAxis);

      this.yAxisContainer = svg.append('g')
        .attr('class', 'y axis')
        .attr('aria-hidden', true)
        .call(this.yAxis);

      barContainer = svg.append('g');

      this.x = x;
      this.height = height;
      this.barContainer = barContainer;

      this.updateChart(svg, props);

      return svg;
    },

    updateChart: function(svg, props) {
      var labelOptions;
      var data = this.chartData = this.calculateChartData(props);
      var avgScore = props.scoreAverage / props.pointsPossible * 100.0;
      labelOptions = this.calculateStudentStatistics(avgScore, data);
      var textForScreenreaders = I18n.t('audible_chart_description',
        '%{above_average} students scored above or at the average, and %{below_average} below. ', {
          above_average: labelOptions.aboveAverage,
          below_average: labelOptions.belowAverage
      })

      data.forEach(function (datum, i) {
        if (datum !== 0) {
          textForScreenreaders += I18n.t({
              one: "1 student in percentile %{percentile}. ",
              other: "%{count} students in percentile %{percentile}. "
            },{
              count: datum,
              percentile: i + ''
            }
          )
        }
      })

      this.title.text(I18n.t('chart_title', 'Score percentiles chart'));
      this.description.text(textForScreenreaders);

      this.renderBars(this.barContainer, props);
    },

    renderBars: function(svg, props) {
      var height, x, y, bars;
      var highest;
      var step;
      var visibilityThreshold;
      var data = this.chartData;

      height = this.height;
      highest = max(data);

      x = this.x;
      y = this.y

      y.range([0, highest])
       .rangeRound([height, 0])
       .domain([0, highest]);

      step = -Math.ceil((highest + 1) / props.numTicks)

      this.yAxis.tickValues(d3.range(highest, 0, step))
        .tickFormat(function(d){return Math.floor(d)});

      this.yAxisContainer.call(this.yAxis).selectAll('text').attr('dy', '.8em');
      this.yAxisContainer
        .selectAll('line')
          .attr('y1', '.5')
          .attr('y2', '.5');

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
        .attr('y', function(d) { return y(d) - visibilityThreshold; })
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

    render: ChartMixin.defaults.render
  });

  return ScorePercentileChart;
});

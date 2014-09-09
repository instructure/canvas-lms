/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var K = require('../../constants');
  var I18n = require('i18n!quiz_statistics');
  var classSet = require('../../util/class_set');
  var ChartMixin = require('../../mixins/chart');
  var Dialog = require('jsx!../../components/dialog');
  var Help = require('jsx!./discrimination_index/help');
  var formatNumber = require('../../util/format_number');

  var divide = function(x, y) {
    return (parseFloat(x) / y) || 0;
  };

  var Chart = React.createClass({
    mixins: [ ChartMixin.mixin ],

    getDefaultProps: function() {
      return {
        correct: [],
        total: [],
        ratio: []
      };
    },

    createChart: function(node, props) {
      var barHeight, barWidth, svg;

      barHeight = props.height / 3;
      barWidth = props.width / 2;

      svg = d3.select(node)
        .attr('width', props.width)
        .attr('height', props.height)
        .append('g');

      svg.selectAll('.bar.correct')
        .data(props.ratio)
        .enter()
          .append('rect')
          .attr('class', 'bar correct')
          .attr('x', barWidth)
          .attr('width', function(correctRatio) {
            return correctRatio * barWidth;
          }).attr('y', function(d, bracket) {
            return bracket * barHeight;
          }).attr('height', function() {
            return barHeight - 1;
          });

      svg.selectAll('.bar.incorrect')
        .data(props.ratio)
        .enter()
          .append('rect')
          .attr('class', 'bar incorrect')
          .attr('x', function(correctRatio) {
            return -1 * (1 - correctRatio * barWidth);
          }).attr('width', function(correctRatio) {
            return (1 - correctRatio) * barWidth;
          }).attr('y', function(d, bracket) {
            return bracket * barHeight;
          }).attr('height', function() {
            return barHeight - 1;
          });

      this.__svg = svg;

      return svg;
    },

    render: ChartMixin.defaults.render
  });

  var DiscriminationIndex = React.createClass({
    getDefaultProps: function() {
      return {
        width: 270,
        height: 14 * 3,
        discriminationIndex: 0,
        topStudentCount: 0,
        middleStudentCount: 0,
        bottomStudentCount: 0,
        correctTopStudentCount: 0,
        correctMiddleStudentCount: 0,
        correctBottomStudentCount: 0,
      };
    },

    render: function() {
      var di = this.props.discriminationIndex;
      var sign = di > K.DISCRIMINATION_INDEX_THRESHOLD ? '+' : '-';
      var className = {
        'index': true,
        'positive': sign === '+',
        'negative': sign !== '+'
      };

      var chartData;
      var stats = {
        top: {
          correct: this.props.correctTopStudentCount,
          total: this.props.topStudentCount,
        },
        mid: {
          correct: this.props.correctMiddleStudentCount,
          total: this.props.middleStudentCount,
        },
        bot: {
          correct: this.props.correctBottomStudentCount,
          total: this.props.bottomStudentCount,
        }
      };

      chartData = {
        correct: [
          stats.top.correct, stats.mid.correct, stats.bot.correct
        ],

        total: [
          stats.top.total, stats.mid.total, stats.bot.total
        ],

        ratio: [
          divide(stats.top.correct, stats.top.total),
          divide(stats.mid.correct, stats.mid.total),
          divide(stats.bot.correct, stats.bot.total)
        ]
      };

      chartData.width = this.props.width;
      chartData.height = this.props.height;

      return (
        <section className="discrimination-index-section">
          <p>
            <em className={classSet(className)}>
              <span className="sign">{sign}</span>
              {formatNumber(Math.abs(this.props.discriminationIndex || 0))}
            </em>

            {' '}

            <strong>
              {I18n.t('discrimination_index', 'Discrimination Index')}
            </strong>

            <Dialog
              tagName="i"
              title={I18n.t('discrimination_index_dialog_title', 'The Discrimination Index Chart')}
              content={Help}
              width={550}
              className="chart-help-trigger icon-question"
              aria-label={I18n.t('discrimination_index_dialog_trigger', 'Learn more about the Discrimination Index.')}
              tabIndex="0" />
          </p>

          {Chart(chartData)}
        </section>
      );
    }
  });

  return DiscriminationIndex;
});
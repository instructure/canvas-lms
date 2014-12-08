/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var d3 = require('d3');
  var K = require('../../constants');
  var I18n = require('i18n!quiz_statistics.discrimination_index');
  var classSet = require('../../util/class_set');
  var ChartMixin = require('../../mixins/chart');
  var Dialog = require('jsx!../../components/dialog');
  var Text = require('jsx!../../components/text');
  var ScreenReaderContent = require('jsx!../../components/screen_reader_content');
  var SightedUserContent = require('jsx!../../components/sighted_user_content');
  var Help = require('jsx!./discrimination_index/help');
  var Chart = require('jsx!./discrimination_index/chart');
  var Table = require('jsx!./discrimination_index/table');
  var formatNumber = require('../../util/format_number');

  var divide = function(x, y) {
    return (parseFloat(x) / y) || 0;
  };

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

      // TODO: it would be nice if we move this to the model layer so we don't
      // have to recalculate on each render pass, even though this is view-layer
      // logic...
      var chartData, tableData;
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

      tableData = [
        {
          id: 'top',
          label: I18n.t('audible_top_bracket', 'Top bracket:') + ' ',
          correct: stats.top.correct,
          incorrect: stats.top.total - stats.top.correct,
          correctRatio: Math.round(chartData.ratio[0] * 100)
        },
        {
          id: 'mid',
          label: I18n.t('audible_middle_bracket', 'Middle bracket:') + ' ',
          correct: stats.mid.correct,
          incorrect: stats.mid.total - stats.mid.correct,
          correctRatio: Math.round(chartData.ratio[1] * 100)
        },
        {
          id: 'bot',
          label: I18n.t('audible_bottom_bracket', 'Bottom bracket:') + ' ',
          correct: stats.bot.correct,
          incorrect: stats.bot.total - stats.bot.correct,
          correctRatio: Math.round(chartData.ratio[2] * 100)
        },
      ];

      return (
        <section className="discrimination-index-section">
          <p>
            <SightedUserContent>
              <em className={classSet(className)}>
                <span className="sign">{sign}</span>
                {formatNumber(Math.abs(this.props.discriminationIndex || 0))}
              </em>

              {' '}

              <strong>
                {I18n.t('discrimination_index', 'Discrimination Index')}
              </strong>
            </SightedUserContent>

            <ScreenReaderContent>
              {I18n.t('audible_discrimination_index', 'Discrimination Index: %{number}.', {
                number: formatNumber(this.props.discriminationIndex || 0)
              })}
            </ScreenReaderContent>

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

          <ScreenReaderContent tagName="div">
            <Table brackets={tableData} />
          </ScreenReaderContent>
        </section>
      );
    }
  });

  return DiscriminationIndex;
});

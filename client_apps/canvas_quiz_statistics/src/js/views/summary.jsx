/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var I18n = require('i18n!quiz_statistics.summary');
  var ScorePercentileChart = require('jsx!./summary/score_percentile_chart');
  var Report = require('jsx!./summary/report');
  var secondsToTime = require('../util/seconds_to_time');
  var round = require('../util/round');
  var formatNumber = require('../util/format_number');
  var SightedUserContent = require('jsx!../components/sighted_user_content');
  var ScreenReaderContent = require('jsx!../components/screen_reader_content');

  var Column = React.createClass({
    render: function() {
      return (
        <th scope="col">
          <SightedUserContent tagName="i" className={this.props.icon + ' inline'} />
          {' '}
          {this.props.label}
        </th>
      );
    }
  });

  var Summary = React.createClass({
    getDefaultProps: function() {
      return {
        quizReports: [],
        pointsPossible: 0,
        scoreAverage: 0,
        scoreHigh: 0,
        scoreLow: 0,
        scoreStdev: 0,
        durationAverage: 0,
        scores: {}
      };
    },

    ratioFor: function(score) {
      var quizPoints = parseFloat(this.props.pointsPossible);

      if (quizPoints > 0) {
        return round(score / quizPoints * 100.0, 0, 0);
      }
      else {
        return 0;
      }
    },

    render: function() {
      return(
        <div id="summary-statistics">
          <header className="padded">
            <h3 className="section-title inline">
              {I18n.t('quiz_summary', 'Quiz Summary')}
            </h3>

            <div className="pull-right">
              {this.props.quizReports.map(this.renderReport)}
            </div>
          </header>

          <table className="text-left">
            <ScreenReaderContent tagName="caption" forceSentenceDelimiter>
              {I18n.t('table_description',
                'Summary statistics for all turned in submissions')
              }
            </ScreenReaderContent>

            <thead>
              <tr>
                <Column
                  icon="icon-quiz-stats-avg"
                  label={I18n.t('mean', 'Average Score')} />
                <Column
                  icon="icon-quiz-stats-high"
                  label={I18n.t('high_score', 'High Score')} />
                <Column
                  icon="icon-quiz-stats-low"
                  label={I18n.t('low_score', 'Low Score')} />
                <Column
                  icon="icon-quiz-stats-deviation"
                  label={I18n.t('stdev', 'Standard Deviation')} />
                <Column
                  icon="icon-quiz-stats-time"
                  label={I18n.t('avg_time', 'Average Time')} />
              </tr>
            </thead>

            <tbody>
              <tr>
                <td className="emphasized">
                  {this.ratioFor(this.props.scoreAverage)}%
                </td>
                <td>{this.ratioFor(this.props.scoreHigh)}%</td>
                <td>{this.ratioFor(this.props.scoreLow)}%</td>
                <td>{formatNumber(round(this.props.scoreStdev, 2), 2)}</td>
                <td>
                  <ScreenReaderContent forceSentenceDelimiter>
                    {secondsToTime.toReadableString(this.props.durationAverage)}
                  </ScreenReaderContent>
                  {/*
                    try to hide the [HH:]MM:SS timestamp from SR users because
                    it's not really useful, however this doesn't work in all
                    modes such as the Speak-All mode (at least on VoiceOver)
                  */}
                  <SightedUserContent>
                    {secondsToTime(this.props.durationAverage)}
                  </SightedUserContent>
                </td>
              </tr>
            </tbody>
          </table>

          <ScorePercentileChart
            key="chart"
            scores={this.props.scores}
            scoreAverage={this.props.scoreAverage}
            pointsPossible={this.props.pointsPossible} />
        </div>
      );
    },

    renderReport: function(reportProps) {
      reportProps.key = 'report-' + reportProps.id;
      return Report(reportProps);
    },
  });

  return Summary;
});
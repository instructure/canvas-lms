/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import formatNumber from '../../../util/format_number'
import {useScope as useI18nScope} from '@canvas/i18n'
import parseNumber from '../../../util/parse_number'
import React from 'react'
import Report from './report'
import round from '@canvas/quiz-legacy-client-apps/util/round'
import ScorePercentileChart from './score_percentile_chart'
import ScreenReaderContent from '@canvas/quiz-legacy-client-apps/react/components/screen_reader_content'
import secondsToTime from '@canvas/quiz-legacy-client-apps/util/seconds_to_time'
import SectionSelect from './section_select'
import SightedUserContent from '@canvas/quiz-legacy-client-apps/react/components/sighted_user_content'
import Spinner from '@canvas/quiz-legacy-client-apps/react/components/spinner'
import {
  IconQuizStatsAvgLine,
  IconQuizStatsDeviationLine,
  IconQuizStatsHighLine,
  IconQuizStatsLowLine,
  IconQuizStatsTimeLine,
} from '@instructure/ui-icons'

const I18n = useI18nScope('quiz_statistics.summary')

const NA_LABEL = I18n.t('not_available_abbrev', 'N/A')

const Column = props => (
  <th scope="col">
    <SightedUserContent tagName="i" className="inline">
      {props.icon}
    </SightedUserContent>{' '}
    {props.label}
  </th>
)

class Summary extends React.Component {
  static defaultProps = {
    quizReports: [],
    pointsPossible: 0,
    scoreAverage: 0,
    scoreHigh: 0,
    scoreLow: 0,
    scoreStdev: 0,
    durationAverage: 0,
    scores: {},
  }

  render() {
    const isLoading = this.props.loading

    return (
      <div
        className={isLoading ? 'loading' : undefined}
        data-testid="summary-statistics"
        id="summary-statistics"
      >
        <header className="padded">
          <h2 className="section-title inline">{I18n.t('quiz_summary', 'Quiz Summary')}</h2>

          {isLoading && <Spinner />}

          <div className="pull-right inline">
            <SectionSelect />
            {this.props.quizReports.map(this.renderReport.bind(this))}
          </div>
        </header>

        <table className="text-left">
          <ScreenReaderContent tagName="caption" forceSentenceDelimiter={true}>
            {I18n.t('table_description', 'Summary statistics for all turned in submissions')}
          </ScreenReaderContent>

          <thead>
            <tr>
              <Column icon={<IconQuizStatsAvgLine />} label={I18n.t('mean', 'Average Score')} />
              <Column icon={<IconQuizStatsHighLine />} label={I18n.t('high_score', 'High Score')} />
              <Column icon={<IconQuizStatsLowLine />} label={I18n.t('low_score', 'Low Score')} />
              <Column
                icon={<IconQuizStatsDeviationLine />}
                label={I18n.t('stdev', 'Standard Deviation')}
              />
              <Column icon={<IconQuizStatsTimeLine />} label={I18n.t('avg_time', 'Average Time')} />
            </tr>
          </thead>

          <tbody>
            <tr>
              <td className="emphasized">
                {isLoading ? NA_LABEL : this.ratioFor(this.props.scoreAverage) + '%'}
              </td>
              <td>{isLoading ? NA_LABEL : this.ratioFor(this.props.scoreHigh) + '%'}</td>
              <td>{isLoading ? NA_LABEL : this.ratioFor(this.props.scoreLow) + '%'}</td>
              <td>{isLoading ? NA_LABEL : formatNumber(round(this.props.scoreStdev, 2), 2)}</td>

              {isLoading ? (
                <td key="duration">{NA_LABEL}</td>
              ) : (
                <td key="duration">
                  <ScreenReaderContent forceSentenceDelimiter={true}>
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
              )}
            </tr>
          </tbody>
        </table>

        <ScorePercentileChart
          key="chart"
          scores={this.props.scores}
          scoreAverage={this.props.scoreAverage}
          pointsPossible={this.props.pointsPossible}
        />
      </div>
    )
  }

  renderReport(reportProps) {
    return <Report key={'report-' + reportProps.id} {...reportProps} />
  }

  ratioFor(score) {
    const quizPoints = parseNumber(this.props.pointsPossible)

    if (quizPoints > 0) {
      return round((score / quizPoints) * 100.0, 0, 0)
    } else {
      return 0
    }
  }
}

export default Summary

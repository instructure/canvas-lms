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

import d3 from 'd3'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import UserListDialog from './user_list_dialog'

const I18n = useI18nScope('quiz_statistics.answer_table')

const SPECIAL_DATUM_IDS = ['other', 'none']

class AnswerRow extends React.Component {
  static propTypes = {
    datum: PropTypes.shape({
      id: PropTypes.string,
      correct: PropTypes.bool,
      special: PropTypes.bool,
      count: PropTypes.number,
      answer: PropTypes.shape({
        ratio: PropTypes.number,
      }),
    }).isRequired,
    globalSettings: PropTypes.object.isRequired,
  }

  state = {
    neverLoaded: true,
  }

  dialogBuilder(answer) {
    if (answer.user_names && answer.user_names.length) {
      return (
        <div>
          <UserListDialog
            key={answer.id + answer.poolId}
            answer_id={answer.id}
            user_names={answer.user_names}
          />
        </div>
      )
    } else if (answer.responses > 0) {
      return (
        <div>
          {I18n.t(
            {
              one: '1 respondent',
              other: '%{count} respondents',
            },
            {count: answer.responses}
          )}
        </div>
      )
    }
  }

  renderBarPlot() {
    const checkAltText = I18n.t('correct check icon')

    return (
      <div
        key={this.props.datum.id}
        className={this.getBarClass()}
        style={this.getBarStyles()}
        alt={I18n.t('Graph bar')}
        title={this.props.datum.correct ? I18n.t('Correct Answer') : I18n.t('Incorrect Answer')}
      >
        {this.props.datum.correct && <i className="icon-check" alt={checkAltText} />}
      </div>
    )
  }

  componentDidMount() {
    this.setState({neverLoaded: false})
  }

  getScoreValueDescription(datum) {
    let string
    switch (datum.id) {
      case 'top':
        string = I18n.t('Answers which scored in the top 27%')
        break
      case 'middle':
        string = I18n.t('Answers which scored in the middle 46%')
        break
      case 'bottom':
        string = I18n.t('Answers which scored in the bottom 27%')
        break
      case 'ungraded':
        string = I18n.t('Ungraded answers')
        break
      default:
        string = I18n.t('Unknown answers')
    }
    return string
  }

  getBarStyles() {
    let width =
      this.props.globalSettings.xScale(this.props.datum.count) +
      this.props.globalSettings.visibilityThreshold +
      'px'
    // Hacky way to get initial state width animations
    if (this.state.neverLoaded) {
      width = '0px'
    }
    return {
      width,
      height: this.props.globalSettings.barHeight - 2 + 'px',
    }
  }

  getBarClass() {
    const className = this.props.datum.correct ? 'bar bar-highlighted' : 'bar'
    return this.props.datum.special ? className + ' bar-striped' : className
  }

  render() {
    const datum = this.props.datum
    const answerText = this.props.globalSettings.useAnswerBuckets
      ? this.getScoreValueDescription(datum)
      : datum.answer.text
    // describedby doesn't seem to be working so I'm simulating what it would be doing with an aria-label
    const answerLabel = this.props.datum.correct
      ? I18n.t('%{answer}, (Correct answer)', {answer: answerText})
      : I18n.t('%{answer}, (Incorrect answer)', {answer: answerText})

    return (
      <tr className={datum.correct ? 'correct' : undefined}>
        <th scope="row" className="answer-textfield">
          <span className="screenreader-only">{answerLabel}</span>
          <span
            className="answerText"
            aria-hidden="true"
            dangerouslySetInnerHTML={{__html: answerText}}
          />
        </th>
        <td className="respondent-link">{this.dialogBuilder(datum.answer)}</td>
        <td className="answer-ratio">
          {datum.answer.ratio} <sup>{I18n.t('%')}</sup>
        </td>
        <td
          className="answer-distribution-cell"
          aria-hidden={true}
          style={{width: this.props.globalSettings.maxWidth}}
        >
          {this.renderBarPlot()}
        </td>
      </tr>
    )
  }
}

class AnswerTable extends React.Component {
  static propTypes = {
    answers: PropTypes.array.isRequired,
    barHeight: PropTypes.number,
    maxWidth: PropTypes.number,
    useAnswerBuckets: PropTypes.bool,
    visibilityThreshold: PropTypes.number,
  }

  static defaultProps = {
    answers: [],

    /**
     * @property {Number} [barHeight=30]
     *
     * Prefered width of the bars in pixels.
     */
    barHeight: 30,

    // padding: 0.05,

    /**
     * @property {Number} [visibilityThreshold=5]
     *
     * An amount of pixels to use for a bar's width in the special case
     * where an answer has received no responses (e.g, y=0).
     *
     * Setting this to a positive number would show the bar for such answers
     * so that the tooltip can be triggered.
     */
    visibilityThreshold: 5,

    maxWidth: 150,

    useAnswerBuckets: false,
  }

  render() {
    const data = this.buildParams(this.props.answers)
    const highest = d3.max(data.map(x => x.count))
    const xScale = d3.scale.linear().domain([highest, 0]).range([this.props.maxWidth, 0])
    const visibilityThreshold = Math.max(this.props.visibilityThreshold, xScale(highest) / 100.0)
    const globalParams = {
      xScale,
      visibilityThreshold,
      maxWidth: this.props.maxWidth,
      barHeight: this.props.barHeight,
      useAnswerBuckets: this.props.useAnswerBuckets,
    }

    return (
      <table className="answer-drilldown-table detail-section">
        <caption className="screenreader-only">
          {I18n.t('A table of answers and brief statistics regarding student answer choices.')}
        </caption>
        {this.renderTableHeader()}
        <tbody>{this.renderTableRows(data, globalParams)}</tbody>
      </table>
    )
  }

  renderTableHeader() {
    const firstColumnLabel = this.props.useAnswerBuckets
      ? I18n.t('Answer Description')
      : I18n.t('Answer Text')
    return (
      <thead className="screenreader-only">
        <tr>
          <th scope="col">{firstColumnLabel}</th>
          <th scope="col">{I18n.t('Number of Respondents')}</th>
          <th scope="col">{I18n.t('Percent of respondents selecting this answer')}</th>
          <th scope="col" aria-hidden={true}>
            {I18n.t('Answer Distribution')}
          </th>
        </tr>
      </thead>
    )
  }

  renderTableRows(data, globalParams) {
    return data.map(function (datum) {
      return <AnswerRow key={datum.id} datum={datum} globalSettings={globalParams} />
    })
  }

  buildParams(answers) {
    return answers.map(function (answer) {
      return {
        id: '' + answer.id,
        count: answer.responses,
        correct: answer.correct || answer.full_credit,
        special: SPECIAL_DATUM_IDS.indexOf(answer.id) > -1,
        answer,
      }
    })
  }
}

export default AnswerTable

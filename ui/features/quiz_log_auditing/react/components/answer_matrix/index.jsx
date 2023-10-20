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

import {useScope as useI18nScope} from '@canvas/i18n'
import InvertedTable from './inverted_table'
import K from '../../../constants'
import Legend from './legend'
import Option from './option'
import React from 'react'
import {Link} from 'react-router-dom'
import Table from './table'

const I18n = useI18nScope('quiz_log_auditing.table_view')

class AnswerMatrix extends React.Component {
  state = {
    activeEventId: null,
    shouldTruncate: false,
    expandAll: false,
    invert: false,
  }

  static defaultProps = {
    questions: [],
    events: [],
    submission: {
      createdAt: new Date().toJSON(),
    },
  }

  render() {
    const events = this.props.events.filter(function (e) {
      return e.type === K.EVT_QUESTION_ANSWERED
    })

    let className

    if (this.state.expandAll) {
      className = 'expanded'
    }

    return (
      <div data-testid="answer-matrix" id="ic-AnswerMatrix" className={className}>
        <h1 className="ic-QuizInspector__Header">
          {I18n.t('Answer Sequence')}

          <div className="ic-QuizInspector__HeaderControls">
            <Option
              onChange={this.setOption.bind(this)}
              name="shouldTruncate"
              label={I18n.t('options.truncate', 'Truncate textual answers')}
              checked={this.state.shouldTruncate}
            />

            <Option
              onChange={this.setOption.bind(this)}
              name="expandAll"
              label={I18n.t('options.expand_all', 'Expand all answers')}
              checked={this.state.expandAll}
            />

            <Option
              onChange={this.setOption.bind(this)}
              name="invert"
              label={I18n.t('options.invert', 'Invert')}
              checked={this.state.invert}
            />

            <Link to={{pathname: '/', search: window.location.search}} className="btn btn-default">
              {I18n.t('buttons.go_to_stream', 'View Stream')}
            </Link>
          </div>
        </h1>

        <Legend />

        <div className="table-scroller">
          {this.state.invert ? this.renderInverted(events) : this.renderNormal(events)}
        </div>
      </div>
    )
  }

  renderNormal(events) {
    return (
      <Table
        events={events}
        questions={this.props.questions}
        submission={this.props.submission}
        expandAll={this.state.expandAll}
        shouldTruncate={this.state.shouldTruncate}
        maxVisibleChars={this.props.maxVisibleChars}
      />
    )
  }

  renderInverted(events) {
    return (
      <InvertedTable
        events={events}
        questions={this.props.questions}
        submission={this.props.submission}
        expandAll={this.state.expandAll}
        shouldTruncate={this.state.shouldTruncate}
        activeEventId={this.state.activeEventId}
        maxVisibleChars={this.props.maxVisibleChars}
      />
    )
  }

  setOption(option, isChecked) {
    const newState = {}

    newState[option] = isChecked

    this.setState(newState)
  }
}

export default AnswerMatrix

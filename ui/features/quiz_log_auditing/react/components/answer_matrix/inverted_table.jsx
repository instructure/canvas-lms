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

import Cell from './cell'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import secondsToTime from '@canvas/quiz-legacy-client-apps/util/seconds_to_time'

const I18n = useI18nScope('quiz_log_auditing.inverted_table_view')

/**
 * @class Events.Views.AnswerMatrix.InvertedTable
 *
 * A table displaying the event series on the X axis, and the questions
 * on the Y axis. This table is optimal for inspecting answer contents, while
 * the "normal" table is optimized for viewing the answer sequence.
 */
class InvertedTable extends React.Component {
  state = {
    activeQuestionId: null,
  }

  render() {
    return (
      <table className="ic-AnswerMatrix__Table ic-Table ic-Table--hover-row ic-Table--striped">
        <thead>
          <tr className="ic-Table__row--bg-neutral">
            <th key="question">{I18n.t('Question')}</th>

            {this.props.events.map(this.renderHeaderCell.bind(this))}
          </tr>
        </thead>

        <tbody>{this.props.questions.map(this.renderContentRow.bind(this))}</tbody>
      </table>
    )
  }

  renderHeaderCell(event) {
    const secondsSinceStart =
      (new Date(event.createdAt) - new Date(this.props.submission.startedAt)) / 1000

    return <th key={'header-' + event.id}>{secondsToTime(secondsSinceStart)}</th>
  }

  renderContentRow(question) {
    const expanded = this.props.expandAll || question.id === this.state.activeQuestionId
    const shouldTruncate = this.props.shouldTruncate

    return (
      <tr
        key={'question-' + question.id}
        onClick={this.toggleAnswerVisibility.bind(this, question)}
        data-testid={`question-toggler-${question.id}`}
      >
        <td key="question">{question.id}</td>

        {this.props.events.map(event => (
          <td key={['q', question.id, 'e', event.id].join('_')}>
            <Cell
              question={question}
              event={event}
              expanded={expanded}
              shouldTruncate={shouldTruncate}
              maxVisibleChars={this.props.maxVisibleChars}
            />
          </td>
        ))}
      </tr>
    )
  }

  toggleAnswerVisibility(question) {
    this.setState(state => ({
      activeQuestionId: question.id === state.activeQuestionId ? null : question.id,
    }))
  }
}

export default InvertedTable

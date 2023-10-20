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

const I18n = useI18nScope('quiz_log_auditing.table_view')

/**
 * @class Events.Views.AnswerMatrix.Table
 *
 * A table displaying the sequence of answers the student has provided to all
 * the questions. The answer cells will variate in shape based on the presence
 * of the answer and its position.
 *
 * @see Events.Views.AnswerMatrix.Emblem
 *
 * @seed A table of 8 questions and 25 events.
 *   "apps/events/test/fixtures/loaded_table.json"
 */
class Table extends React.Component {
  state = {
    activeEventId: null,
  }

  static defaultProps = {
    questions: [],
    events: [],
    submission: {},
  }

  render() {
    return (
      <table className="ic-AnswerMatrix__Table ic-Table ic-Table--hover-row  ic-Table--condensed">
        <thead>
          <tr className="ic-Table__row--bg-neutral">
            <th key="timestamp">
              <div>{I18n.t('headers.timestamp', 'Timestamp')}</div>
            </th>

            {this.props.questions.map(this.renderHeaderCell.bind(this))}
          </tr>
        </thead>

        <tbody>{this.props.events.map(this.renderContentRow.bind(this))}</tbody>
      </table>
    )
  }

  renderHeaderCell(question) {
    return (
      <th key={'question-' + question.id}>
        <div>
          {I18n.t('headers.question', 'Question %{position}', {
            position: question.position,
          })}

          <small>({question.id})</small>
        </div>
      </th>
    )
  }

  renderContentRow(event) {
    let className
    const expanded = this.props.expandAll || event.id === this.state.activeEventId
    const shouldTruncate = this.props.shouldTruncate
    const secondsSinceStart =
      (new Date(event.createdAt) - new Date(this.props.submission.startedAt)) / 1000

    if (this.props.activeEventId === event.id) {
      className = 'active'
    }

    return (
      <tr
        key={'event-' + event.id}
        className={className}
        onClick={this.toggleAnswerVisibility.bind(this, event)}
        data-testid={`event-toggler-${event.id}`}
      >
        <td>{secondsToTime(secondsSinceStart)}</td>

        {this.props.questions.map(question => (
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

  toggleAnswerVisibility(event) {
    this.setState(state => ({
      activeEventId: event.id === state.activeEventId ? null : event.id,
    }))
  }
}

export default Table

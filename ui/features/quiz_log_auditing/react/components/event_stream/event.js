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
import K from '../../../constants'
import React from 'react'
import secondsToTime from '@canvas/quiz-legacy-client-apps/util/seconds_to_time'
import SightedUserContent from '@canvas/quiz-legacy-client-apps/react/components/sighted_user_content'
import {Link} from 'react-router-dom'
import {IconTroubleLine, IconCompleteLine, IconEmptyLine} from '@instructure/ui-icons'

const I18n = useI18nScope('quiz_log_auditing.event_stream')

class Event extends React.Component {
  static defaultProps = {
    startedAt: new Date(),
  }

  render() {
    const e = this.props

    return (
      <li className="ic-ActionLog__Entry" key={'event-' + e.id}>
        {this.renderRow(e)}
      </li>
    )
  }

  renderRow(e) {
    const secondsSinceStart = (new Date(e.createdAt) - new Date(e.startedAt)) / 1000

    return (
      <div>
        <span className="ic-ActionLog__EntryTimestamp">{secondsToTime(secondsSinceStart)}</span>

        <SightedUserContent className="ic-ActionLog__EntryFlag">
          {this.renderFlag(e.flag)}
        </SightedUserContent>

        <div className="ic-ActionLog__EntryDescription">{this.renderDescription(e)}</div>
      </div>
    )
  }

  renderFlag(flag) {
    if (flag === K.EVT_FLAG_WARNING) {
      return <IconTroubleLine color="warning" />
    } else if (flag === K.EVT_FLAG_OK) {
      return <IconCompleteLine color="success" />
    } else {
      return <IconEmptyLine color="secondary" />
    }
  }

  renderDescription(event) {
    switch (event.type) {
      case K.EVT_SESSION_STARTED:
        return I18n.t('session_started', 'Session started')

      case K.EVT_QUESTION_ANSWERED: {
        const valid_answers = event.data.filter(function (i) {
          return i.answer != null
        })

        if (valid_answers.length === 0) {
          return null
        }

        return (
          <div>
            {I18n.t(
              'question_answered',
              {
                one: 'Answered question:',
                other: 'Answered the following questions:',
              },
              {count: valid_answers.length}
            )}

            <div className="ic-QuestionAnchors">
              {valid_answers.map(this.renderQuestionAnchor.bind(this))}
            </div>
          </div>
        )
      }

      case K.EVT_QUESTION_VIEWED:
        return (
          <div>
            {I18n.t(
              'question_viewed',
              {
                one: 'Viewed (and possibly read) question',
                other: 'Viewed (and possibly read) the following questions:',
              },
              {count: event.data.length}
            )}

            <div className="ic-QuestionAnchors">
              {event.data.map(this.renderQuestionAnchor.bind(this))}
            </div>
          </div>
        )

      case K.EVT_PAGE_BLURRED:
        return I18n.t('page_blurred', 'Stopped viewing the Canvas quiz-taking page...')

      case K.EVT_PAGE_FOCUSED:
        return I18n.t('page_focused', 'Resumed.')

      case K.EVT_QUESTION_FLAGGED: {
        let label

        if (event.data.flagged) {
          label = I18n.t('question_flagged', 'Flagged question:')
        } else {
          label = I18n.t('question_unflagged', 'Unflagged question:')
        }

        return (
          <div>
            {label}

            <div className="ic-QuestionAnchors">
              {this.renderQuestionAnchor(event.data.questionId)}
            </div>
          </div>
        )
      }

      default:
        return null
    }
  }

  renderQuestionAnchor(record) {
    let id
    let question
    let position

    if (typeof record === 'object') {
      id = record.quizQuestionId
    } else {
      id = record
    }

    question = this.props.questions.find(q => {
      return q.id === id
    })

    position = question && question.position

    return (
      <Link
        key={'question-anchor' + id}
        to={{
          pathname: `/questions/${id}`,
          search: `?event=${this.props.id}&attempt=${this.props.attempt}`,
        }}
        className="ic-QuestionAnchors__Anchor"
      >
        {'#' + position}
      </Link>
    )
  }
}

export default Event

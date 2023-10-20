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

import Event from './event'
import {useScope as useI18nScope} from '@canvas/i18n'
import K from '../../../constants'
import React from 'react'

const I18n = useI18nScope('quiz_log_auditing.event_stream')

const visibleEventTypes = [
  K.EVT_PAGE_BLURRED,
  K.EVT_PAGE_FOCUSED,
  K.EVT_QUESTION_ANSWERED,
  K.EVT_QUESTION_FLAGGED,
  K.EVT_QUESTION_VIEWED,
  K.EVT_SESSION_STARTED,
]

class EventStream extends React.Component {
  static defaultProps = {
    events: [],
    submission: {},
    questions: [],
  }

  render() {
    const visibleEvents = this.getVisibleEvents(this.props.events)

    return (
      <div data-testid="event-stream" id="ic-EventStream">
        <h2>{I18n.t('headers.action_log', 'Action Log')}</h2>

        {visibleEvents.length === 0 && (
          <p>
            {I18n.t(
              'notices.no_events_available',
              'There were no events logged during the quiz-taking session.'
            )}
          </p>
        )}

        <ol id="ic-EventStream__ActionLog">{visibleEvents.map(this.renderEvent.bind(this))}</ol>
      </div>
    )
  }

  renderEvent(e) {
    const props = {
      ...e,
      startedAt: this.props.submission.startedAt,
      questions: this.props.questions,
      attempt: this.props.attempt,
    }

    return <Event key={e.id} {...props} />
  }

  getVisibleEvents(events) {
    return events.filter(function (e) {
      if (visibleEventTypes.indexOf(e.type) === -1) {
        return false
      }
      if (e.type !== K.EVT_QUESTION_ANSWERED) {
        return true
      }
      return e.data.some(i => {
        return i.answer != null
      })
    })
  }
}

export default EventStream

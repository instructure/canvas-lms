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
import React from 'react'
import {Link} from 'react-router-dom'
import {IconArrowStartLine} from '@instructure/ui-icons'

const I18n = useI18nScope('quiz_log_auditing.navigation')

class QuestionListing extends React.Component {
  static defaultProps = {
    questions: [],
    activeQuestionId: undefined,
    activeEventId: undefined,
  }

  render() {
    return (
      <div>
        <h2>{I18n.t('questions', 'Questions')}</h2>

        <ol id="ic-QuizInspector__QuestionListing">
          {this.props.questions
            .sort(function (a, b) {
              return a.position > b.position
            })
            .map(this.renderQuestion.bind(this))}
        </ol>

        <Link
          className="no-hover"
          to={{
            pathname: '/',
            search: window.location.search,
          }}
        >
          <IconArrowStartLine /> {I18n.t('links.back_to_session_information', 'Back to Log')}
        </Link>
      </div>
    )
  }

  renderQuestion(question) {
    return (
      <li key={question.id}>
        <Link
          className={this.props.activeQuestionId === question.id ? 'active' : undefined}
          to={{
            pathname: `/questions/${question.id}`,
            search: window.location.search,
          }}
        >
          {I18n.t('links.question', 'Question %{position}', {
            position: question.position,
          })}
        </Link>
      </li>
    )
  }
}

export default QuestionListing

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

import $ from 'jquery'
import Answer from './answer'
import classSet from '@canvas/quiz-legacy-client-apps/util/class_set'
import {useScope as useI18nScope} from '@canvas/i18n'
import K from '../../../constants'
import NoAnswer from './answers/no_answer'
import React from 'react'

const I18n = useI18nScope('quiz_log_auditing')

class QuestionInspector extends React.Component {
  static defaultProps = {
    question: undefined,
    events: [],
  }

  componentDidMount() {
    $('body').addClass('with-right-side')
  }

  componentWillUnmount() {
    $('body').removeClass('with-right-side')
  }

  render() {
    return (
      <div id="ic-QuizInspector__QuestionInspector">
        {this.props.question && this.renderQuestion(this.props.question)}
      </div>
    )
  }

  renderQuestion(question) {
    const currentEventId = this.props.currentEventId
    const answers = []
    this.props.events
      .filter(function (event) {
        return (
          event.type === K.EVT_QUESTION_ANSWERED &&
          event.data.some(function (record) {
            return record.quizQuestionId === question.id
          })
        )
      })
      .sort(function (a, b) {
        return new Date(a.createdAt) - new Date(b.createdAt)
      })
      .forEach(function (event) {
        const records = event.data.filter(function (record) {
          return record.quizQuestionId === question.id
        })

        records.forEach(function (record) {
          answers.push({
            active: event.id === currentEventId,
            value: record.answer,
            answered: record.answered,
          })
        })
      })

    return (
      <div>
        <h1 className="ic-QuestionInspector__QuestionHeader">
          {I18n.t('question_header', 'Question #%{position}', {
            position: question.position,
          })}

          <span className="ic-QuestionInspector__QuestionType">
            {I18n.t('question_type', '%{type}', {type: question.readableType})}
          </span>

          <span className="ic-QuestionInspector__QuestionId">(id: {question.id})</span>
        </h1>

        <div
          className="ic-QuestionInspector__QuestionText"
          dangerouslySetInnerHTML={{__html: question.questionText}}
        />

        <hr />

        <p>
          {I18n.t(
            'question_response_count',
            {
              zero: 'This question was never answered.',
              one: 'This question was answered once.',
              other: 'This question was answered %{count} times.',
            },
            {count: answers.length}
          )}
        </p>

        <ol id="ic-QuestionInspector__Answers">{answers.map(this.renderAnswer.bind(this))}</ol>
      </div>
    )
  }

  renderAnswer(record, index) {
    let answer
    const className = classSet({
      'ic-QuestionInspector__Answer': true,
      'ic-QuestionInspector__Answer--is-active': !!record.active,
    })

    if (record.answered) {
      answer = (
        <Answer
          key={'answer-' + index}
          answer={record.value}
          isActive={record.active}
          question={this.props.question}
        />
      )
    } else {
      answer = <NoAnswer />
    }

    return (
      <li key={'answer-' + index} className={className}>
        {answer}
      </li>
    )
  }
}

export default QuestionInspector

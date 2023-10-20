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

import AnswerTable from './answer_table'
import calculateResponseRatio from '../../../backbone/models/ratio_calculator'
import classSet from '@canvas/quiz-legacy-client-apps/util/class_set'
import CorrectAnswerDonut from '../correct_answer_donut'
import {useScope as useI18nScope} from '@canvas/i18n'
import Question from '../question'
import QuestionHeader from './header'
import React from 'react'
import round from '@canvas/quiz-legacy-client-apps/util/round'

const I18n = useI18nScope('quiz_statistics')

class FillInMultipleBlanks extends React.Component {
  state = {
    answerSetId: null,
    answerSetQuestionId: null,
  }

  static defaultProps = {
    answerSets: [],
  }

  render() {
    const crr = calculateResponseRatio(this.getAnswerPool(), this.props.participantCount, {
      questionType: this.props.questionType,
    })
    const answerPool = this.getAnswerPool()

    return (
      <Question>
        <div className="grid-row">
          <div className="col-sm-8 question-top-left">
            <QuestionHeader
              responseCount={this.props.responses}
              participantCount={this.props.participantCount}
              questionText={this.props.questionText}
              position={this.props.position}
            />

            <div
              className="question-text"
              aria-hidden={true}
              dangerouslySetInnerHTML={{__html: this.props.questionText}}
            />

            <nav className="row-fluid answer-set-tabs">
              {this.props.answerSets.map(this.renderAnswerSetTab.bind(this))}
            </nav>
          </div>

          <div className="col-sm-4 question-top-right" />
        </div>

        <div className="grid-row">
          <div className="col-sm-8 question-bottom-left" data-testid="answer-table">
            <AnswerTable answers={answerPool} />
          </div>

          <div className="col-sm-4 question-bottom-right">
            <CorrectAnswerDonut
              correctResponseRatio={crr}
              label={I18n.t('%{ratio}% responded correctly', {
                ratio: round(crr * 100.0, 0),
              })}
            />
          </div>
        </div>
      </Question>
    )
  }

  renderAnswerSetTab(answerSet) {
    const id = answerSet.id
    const className = classSet({
      active: this.getAnswerSetId() === id,
    })

    return (
      <button
        key={'answerSet-' + id}
        type="button"
        data-testid={`choose-answer-set-${id}`}
        onClick={this.switchAnswerSet.bind(this, id)}
        className={className}
      >
        {answerSet.text}
      </button>
    )
  }

  getAnswerPool() {
    const answerSetId = this.getAnswerSetId()
    const answerSet = this.props.answerSets.find(answerSet => answerSet.id === answerSetId)

    if (answerSet) {
      return answerSet.answers.map(answer => ({...answer, poolId: answerSetId}))
    } else {
      return []
    }
  }

  getAnswerSetId() {
    if (this.props.id === this.state.answerSetQuestionId && this.state.answerSetId) {
      return this.state.answerSetId
    } else {
      return (this.props.answerSets[0] || {}).id
    }
  }

  switchAnswerSet(answerSetId, e) {
    e.preventDefault()

    this.setState({
      answerSetId,
      answerSetQuestionId: this.props.id,
    })
  }
}

export default FillInMultipleBlanks

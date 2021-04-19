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
import CorrectAnswerDonut from '../correct_answer_donut'
import Question from '../question'
import QuestionHeader from './header'
import React from 'react'

const ShortAnswer = props => (
  <Question>
    <div className="grid-row">
      <div className="col-sm-8 question-top-left">
        <QuestionHeader
          responseCount={props.responses}
          participantCount={props.participantCount}
          questionText={props.questionText}
          position={props.position}
        />

        <div
          className="question-text"
          aria-hidden
          dangerouslySetInnerHTML={{__html: props.questionText}}
        />
      </div>
      <div className="col-sm-4 question-top-right" />
    </div>
    <div className="grid-row">
      <div className="col-sm-8 question-bottom-left">
        <AnswerTable answers={props.answers} />
      </div>
      <div className="col-sm-4 question-bottom-right">
        <CorrectAnswerDonut
          correctResponseRatio={calculateResponseRatio(props.answers, props.participantCount, {
            correctResponseCount: props.correct,
            questionType: props.questionType
          })}
        />
      </div>
    </div>
  </Question>
)

export default ShortAnswer

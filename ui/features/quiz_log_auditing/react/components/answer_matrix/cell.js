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

import React from 'react'
import K from '../../../constants'
import Emblem from './emblem'

// These questions types will have their answer cells truncated if it goes
// over the character visibility threshold:
const FREE_FORM_QUESTION_TYPES = [K.Q_ESSAY, K.Q_SHORT_ANSWER]

/**
 * @class Cell
 * @memberOf Views.AnswerMatrix
 *
 * A table cell that renders an answer to a question, based on the question
 * type, the table options, and other things.
 */
const Cell = props => {
  let formattedAnswer, answerSz, encodeAsJson
  const record = props.event.data.find(x => x.quizQuestionId === props.question.id)

  if (!record) {
    return null
  }

  formattedAnswer = record.answer
  encodeAsJson = true

  // show the answer only if the expandAll option is turned on, or the
  // current event is activated (i.e, the row was clicked):
  if (props.expanded) {
    if (FREE_FORM_QUESTION_TYPES.indexOf(props.question.questionType) > -1) {
      encodeAsJson = false

      if (props.shouldTruncate) {
        formattedAnswer = record.answer || ''
        answerSz = formattedAnswer.length

        if (answerSz > props.maxVisibleChars) {
          formattedAnswer = formattedAnswer.substr(0, props.maxVisibleChars)
          formattedAnswer += '...'
        }
      }
    }

    return (
      <pre data-testid={`cell-${props.event.id}`}>
        {encodeAsJson ? JSON.stringify(formattedAnswer, null, 2) : formattedAnswer}
      </pre>
    )
  } else {
    return <Emblem {...record} />
  }
}

Cell.defaultProps = {
  expanded: false,
  shouldTruncate: false,
  event: {data: []},
  question: {},
  maxVisibleChars: K.MAX_VISIBLE_CHARS,
}

export default Cell

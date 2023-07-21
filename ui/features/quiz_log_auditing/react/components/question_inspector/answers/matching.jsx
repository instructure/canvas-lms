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

import K from '../../../../constants'
import NO_ANSWER from './no_answer'
import React from 'react'

const Matching = ({answer, question}) => (
  <table>
    <tbody>
      {question.answers.map(questionAnswer => {
        let match
        const answerRecord = answer.find(
          record => String(record.answer_id) === String(questionAnswer.id)
        )

        if (answerRecord) {
          match = question.matches.find(
            match => String(match.match_id) === String(answerRecord.match_id)
          )
        }

        return (
          <tr key={'answer-' + questionAnswer.id}>
            <th scope="col">{questionAnswer.left}</th>
            <td>{match ? match.text : NO_ANSWER}</td>
          </tr>
        )
      })}
    </tbody>
  </table>
)

Matching.questionTypes = [K.Q_MATCHING]

export default Matching

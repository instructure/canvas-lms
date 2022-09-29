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

const MULTIPLE_ANSWERS = 'multiple_answers_question'

export default function calculateResponseRatio(answerPool, participantCount, suppl) {
  let questionType, correctResponseCount

  participantCount = parseInt(participantCount || 0, 10)

  if (participantCount <= 0) {
    return 0
  }

  if (suppl) {
    questionType = suppl.questionType
  }

  // Multiple-Answer question stats already come served with a "correct"
  // field that denotes the count of students who provided a fully correct
  // answer, so we don't have to calculate anything for it.
  if (MULTIPLE_ANSWERS === questionType) {
    correctResponseCount = suppl.correctResponseCount || 0
  } else {
    correctResponseCount = answerPool.reduce(function (sum, answer) {
      return answer.correct ? sum + answer.responses : sum
    }, 0)
  }

  return parseFloat(correctResponseCount) / participantCount
}

/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function() {
  var MULTIPLE_ANSWERS = 'multiple_answers_question'

  /**
   * @member Statistics.Models
   * @method calculateResponseRatio
   *
   * Calculates the ratio of students who answered this question correctly
   * (partially correct answers do not count when applicable)
   *
   * The ratio calculation may differ based on the question type, this class
   * takes care of it by exposing a single API #ratio() that hides those details
   * from you.
   *
   * @param {Object[]} answerPool
   * This is the set of answers that we'll use to calculate the ratio.
   *
   * Synopsis of the expected answer objects in the set:
   *
   *     {
   *       "responses": 0,
   *       "correct": true
   *     }
   *
   * Most question types will have these defined in the top-level "answers" set,
   * but for some others that support answer sets, these could be found in
   * `answer_sets.@each.answer_matches`.
   *
   * @return {Number} A scalar, the ratio.
   */
  return function calculateResponseRatio(answerPool, participantCount, suppl) {
    var questionType, correctResponseCount

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
      correctResponseCount = answerPool.reduce(function(sum, answer) {
        return answer.correct ? sum + answer.responses : sum
      }, 0)
    }

    return parseFloat(correctResponseCount) / participantCount
  }
})

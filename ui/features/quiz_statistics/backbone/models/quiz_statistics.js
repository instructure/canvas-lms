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

import {find} from 'lodash'
import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import K from '../../constants'
import pickAndNormalize from '@canvas/quiz-legacy-client-apps/util/pick_and_normalize'
import round from '@canvas/quiz-legacy-client-apps/util/round'
import wrap from '@canvas/quiz-legacy-client-apps/util/array_wrap'

const I18n = useI18nScope('quiz_statistics')

let parseQuestion

const QuizStatistics = Backbone.Model.extend({
  parse(payload) {
    const attrs = pickAndNormalize(payload, K.QUIZ_STATISTICS_ATTRS)

    attrs.submissionStatistics = pickAndNormalize(
      payload.submission_statistics,
      K.SUBMISSION_STATISTICS_ATTRS
    )

    attrs.questionStatistics = wrap(payload.question_statistics).map(parseQuestion)

    return attrs
  },
})

// @return {Number}
//  Count of participants who were presented with this question and provided
//  any sort of response (even if it's a blank/no response.)
const calculateParticipantCount = function (question) {
  let answerPool

  // pick any answer set; they will all have the same response count, only
  // distributed differently:
  if (question.answerSets && question.answerSets.length > 0) {
    answerPool = question.answerSets[0].answers
  } else {
    answerPool = question.answers
  }
  if (question.questionType === 'multiple_answers_question') {
    return question.responses // This will not indicate a response for blank responses
  }
  return wrap(answerPool).reduce(function (sum, answer) {
    return sum + (answer.responses || 0)
  }, 0)
}

parseQuestion = function (question) {
  let correctAnswerPointBiserials
  const attrs = pickAndNormalize(question, K.QUESTION_STATISTICS_ATTRS)
  const participantCount = calculateParticipantCount(attrs)
  const decorateAnswer = function (answer) {
    if (answer.id === 'none') {
      answer.text = I18n.t('no_answer', 'No Answer')
    } else if (answer.id === 'other') {
      answer.text = I18n.t('unknown_answer', 'Something Else') // This is where we need to handle the answer changed thing
    }

    if (participantCount > 0) {
      answer.ratio = round((answer.responses / participantCount) * 100.0)
    } else {
      answer.ratio = 0
    }
  }

  // This value along with attrs['responses'] will allow us to display how
  // many students who were presented with this question actually left any
  // response.
  //
  // The only thing worth noting here is that attrs['responses'] denotes the
  // number of students who provided _some_ response. Blanks/no responses do
  // not count in that number!
  attrs.participantCount = participantCount

  if (attrs.answers) {
    attrs.answers.forEach(decorateAnswer)
  } else if (attrs.answerSets) {
    attrs.answerSets.forEach(function (answerSet) {
      wrap(answerSet.answers).forEach(decorateAnswer)
    })
  }

  // Extract the discrimination index from the point biserial record for the
  // correct answer. Applies only to MC/TF questions.
  if (attrs.pointBiserials) {
    attrs.pointBiserials = attrs.pointBiserials.map(function (pointBiserial) {
      return pickAndNormalize(pointBiserial, K.POINT_BISERIAL_ATTRS)
    })

    correctAnswerPointBiserials =
      find(attrs.pointBiserials, {
        correct: true,
      }) || {}

    attrs.discriminationIndex = correctAnswerPointBiserials.pointBiserial
  }

  // Calculate the score<>student ratio for Essay (and friends) using the
  // score distribution vector so that we can say "X% of students received a
  // score of Y".
  if (attrs.pointDistribution) {
    attrs.pointDistribution.forEach(function (point) {
      if (participantCount > 0) {
        point.ratio = round((point.count / participantCount) * 100.0)
      } else {
        point.ratio = 0
      }
    })
  }

  return attrs
}

export default QuizStatistics

/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import EventTracker from '../event_tracker'
import K from '../constants'
import $ from 'jquery'
import '../expressions/in_viewport'
import debugConsole from '../util/debugConsole'
import parseQuestionId from '../util/parse_question_id'

export default class QuestionViewed extends EventTracker {
  install(deliver, scrollContainer = window) {
    let viewed = []

    return this.bind(
      scrollContainer,
      'scroll',
      () => {
        const newlyViewed = this.identifyVisibleQuestions().filter(
          questionId => viewed.indexOf(questionId) === -1
        )

        if (newlyViewed.length > 0) {
          viewed = viewed.concat(newlyViewed)

          debugConsole.log(
            `Student has just viewed the following questions: ${newlyViewed}. (Questions viewed up until now are: ${viewed})`
          )

          return deliver(newlyViewed)
        }
      },

      {throttle: this.getOption('frequency')}
    )
  }

  identifyVisibleQuestions() {
    return $('.question[id]:visible').filter(':in_viewport').toArray().map(parseQuestionId)
  }
}
QuestionViewed.prototype.eventType = K.EVT_QUESTION_VIEWED
QuestionViewed.prototype.options = {
  frequency: 2500,
}

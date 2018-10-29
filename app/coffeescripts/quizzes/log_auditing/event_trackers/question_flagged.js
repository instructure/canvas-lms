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
import debugConsole from '../../../util/debugConsole'
import parseQuestionId from '../util/parse_question_id'

export default class QuestionFlagged extends EventTracker {
  install(deliver) {
    $(document.body).on(`click.${this.uid}`, this.getOption('buttonSelector'), e => {
      const $question = $(e.target).closest(this.getOption('questionSelector'))
      const isFlagged = $question.hasClass(this.getOption('questionMarkedClass'))
      const questionId = parseQuestionId($question[0])

      debugConsole.log(
        `Question ${questionId} ${isFlagged ? 'is now flagged' : 'is no longer flagged'}.`
      )

      return deliver({
        flagged: isFlagged,
        questionId
      })
    })
  }
}
QuestionFlagged.prototype.eventType = K.EVT_QUESTION_FLAGGED
QuestionFlagged.prototype.options = {
  buttonSelector: '.flag_question',
  questionSelector: '.question',
  questionMarkedClass: 'marked'
}

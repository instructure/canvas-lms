#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define (require) ->
  EventTracker = require('../event_tracker')
  K = require('../constants')
  $ = require('jquery')
  debugConsole = require('../../../util/debugConsole')
  parseQuestionId = require('../util/parse_question_id')

  class QuestionFlagged extends EventTracker
    eventType: K.EVT_QUESTION_FLAGGED
    options: {
      buttonSelector: '.flag_question'
      questionSelector: '.question'
      questionMarkedClass: 'marked'
    }

    install: (deliver) ->
      $(document.body).on "click.#{@uid}", @getOption('buttonSelector'), (e) =>
        $question = $(e.target).closest(@getOption('questionSelector'))
        isFlagged = $question.hasClass(@getOption('questionMarkedClass'))
        questionId = parseQuestionId($question[0])

        debugConsole.log """
          Question #{questionId} #{
            if isFlagged then 'is now flagged' else 'is no longer flagged'
          }.
        """

        deliver({
          flagged: isFlagged,
          questionId: questionId
        })
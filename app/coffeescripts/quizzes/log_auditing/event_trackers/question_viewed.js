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
  inViewport = require('../../../jquery/expressions/in_viewport')
  debugConsole = require('../../../util/debugConsole')
  parseQuestionId = require('../util/parse_question_id')

  class QuestionViewed extends EventTracker
    eventType: K.EVT_QUESTION_VIEWED
    options: {
      frequency: 2500
    }

    install: (deliver, scrollContainer = window) ->
      viewed = []

      @bind scrollContainer, 'scroll', =>
        newlyViewed = @identifyVisibleQuestions().filter (questionId) ->
          viewed.indexOf(questionId) == -1

        if newlyViewed.length > 0
          viewed = viewed.concat(newlyViewed)

          debugConsole.log """
            Student has just viewed the following questions: #{newlyViewed}.
            (Questions viewed up until now are: #{viewed})
          """

          deliver(newlyViewed)

      , throttle: @getOption('frequency')

    identifyVisibleQuestions: ->
      $('.question[id]:visible')
        .filter(':in_viewport')
        .toArray()
        .map parseQuestionId
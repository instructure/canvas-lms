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

define [
  'compiled/quizzes/log_auditing/event_trackers/question_flagged'
  'compiled/quizzes/log_auditing/constants'
  'jquery'
], (Subject, K, $) ->
  QUnit.module 'Quizzes::LogAuditing::EventTrackers::QuestionFlagged',
    setup: ->
    teardown: ->
      document.getElementById("fixtures").innerHTML = ""

  DEFAULTS = Subject.prototype.options

  createQuestion = (id) ->
    $question = $('<div />', { class: 'question', id: "question_#{id}" })
      .appendTo(document.getElementById("fixtures"))

    $('<a />', { class: 'flag_question' }).appendTo($question).on 'click', ->
      $question.toggleClass('marked')

    QUnit.done -> $question.remove()

    $question

  test '#constructor: it sets up the proper context', ->
    tracker = new Subject()

    equal tracker.eventType, K.EVT_QUESTION_FLAGGED
    equal tracker.priority, K.EVT_PRIORITY_LOW

  test 'capturing: it works', ->
    capture = @stub()
    tracker = new Subject({
      questionSelector: '.question',
      questionMarkedClass: 'marked',
      buttonSelector: '.flag_question',
    })

    tracker.install(capture)

    $fakeQuestion = createQuestion('123')
    $fakeQuestion.find('a.flag_question').click()

    ok capture.calledWith({ questionId: '123', flagged: true })

    $fakeQuestion.find('a.flag_question').click()
    ok capture.calledWith({ questionId: '123', flagged: false })

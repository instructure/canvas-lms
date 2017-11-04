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
  'compiled/quizzes/log_auditing/event_trackers/question_viewed'
  'compiled/quizzes/log_auditing/constants'
  'jquery'
], (Subject, K, $) ->
  QUnit.module 'Quizzes::LogAuditing::EventTrackers::QuestionViewed',
    setup: ->
    teardown: ->
      document.getElementById("fixtures").innerHTML = ""

  createQuestion = (id) ->
    $question = $('<div />', {
      class: 'question',
      id: "question_#{id}"
    }).appendTo(document.getElementById("fixtures"))

    QUnit.done -> $question.remove()

    $question

  test '#constructor: it sets up the proper context', ->
    tracker = new Subject()

    equal tracker.eventType, K.EVT_QUESTION_VIEWED
    equal tracker.priority, K.EVT_PRIORITY_LOW

  test '#identifyVisibleQuestions', ->
    tracker = new Subject()
    createQuestion('123')

    equal(
      JSON.stringify(tracker.identifyVisibleQuestions()),
      JSON.stringify([ '123' ]),
      'it identifies currently visible questions'
    )

  test 'capturing: it works', ->
    tracker = new Subject(frequency: 0)
    capture = @stub()
    tracker.install(capture)

    wh = $(window).height()
    offsetTop = 3500

    $fakeQuestion = createQuestion('123')
    $fakeQuestion.css({
      'height': '1px', # needs some height to be considered visible
      'margin-top': offsetTop
    })

    $(window).scroll()
    ok !capture.called,
      'question should not be marked as viewed just yet'

    $(window).scrollTop($(document).height())
    $(window).scroll()
    ok capture.called,
      'question should now be marked as viewed after scrolling it into viewport'

    capture.reset()

    $(window).scrollTop(0).scroll()
    ok !capture.called

    $(window).scrollTop($(document).height())
    $(window).scroll()
    ok !capture.called,
      'should not track the same question more than one time'

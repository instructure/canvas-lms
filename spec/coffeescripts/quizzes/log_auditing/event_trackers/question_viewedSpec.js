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

import Subject from 'compiled/quizzes/log_auditing/event_trackers/question_viewed'
import K from 'compiled/quizzes/log_auditing/constants'
import $ from 'jquery'

const scrollSelector = 'html, body'
const $scrollContainer = $(scrollSelector)

QUnit.module('Quizzes::LogAuditing::EventTrackers::QuestionViewed', {
  setup() {},
  teardown() {
    document.getElementById('fixtures').innerHTML = ''
  }
})
const createQuestion = function(id) {
  const $question = $('<div />', {
    class: 'question',
    id: `question_${id}`
  }).appendTo(document.getElementById('fixtures'))
  QUnit.done(() => $question.remove())
  return $question
}
test('#constructor: it sets up the proper context', () => {
  const tracker = new Subject()
  equal(tracker.eventType, K.EVT_QUESTION_VIEWED)
  equal(tracker.priority, K.EVT_PRIORITY_LOW)
})

test('#identifyVisibleQuestions', () => {
  const tracker = new Subject()
  createQuestion('123')
  equal(
    JSON.stringify(tracker.identifyVisibleQuestions()),
    JSON.stringify(['123']),
    'it identifies currently visible questions'
  )
})

test('capturing: it works', function() {
  const tracker = new Subject({frequency: 0})
  const capture = sinon.stub()
  tracker.install(capture, scrollSelector)
  const offsetTop = 3500
  const $fakeQuestion = createQuestion('123')
  $fakeQuestion.css({
    height: '1px', // needs some height to be considered visible
    'margin-top': offsetTop
  })
  $scrollContainer.scrollTop(10).scroll()
  ok(!capture.called, 'question should not be marked as viewed just yet')
  $scrollContainer.scrollTop(offsetTop).scroll()
  ok(capture.called, 'question should now be marked as viewed after scrolling it into viewport')
  capture.reset()
  $scrollContainer.scrollTop(0).scroll()
  ok(!capture.called)
  $scrollContainer.scrollTop(offsetTop).scroll()
  ok(!capture.called, 'should not track the same question more than one time')
})

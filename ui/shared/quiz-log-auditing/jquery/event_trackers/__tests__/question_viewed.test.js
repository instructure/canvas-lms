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

import Subject from '../question_viewed'
import K from '../../constants'
import $ from 'jquery'
import sinon from 'sinon'

const equal = (x, y) => expect(x).toBe(y)
const ok = x => expect(x).toBeTruthy()

const scrollSelector = 'html, body'
const $scrollContainer = $(scrollSelector)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const createQuestion = function (id) {
  const $question = $('<div />', {
    class: 'question',
    id: `question_${id}`,
  }).appendTo(document.getElementById('fixtures'))
  // QUnit.done(() => $question.remove())
  return $question
}

describe('Quizzes::LogAuditing::EventTrackers::QuestionViewed', () => {
  afterEach(() => {
    document.getElementById('fixtures').innerHTML = ''
  })

  test('#constructor: it sets up the proper context', () => {
    const tracker = new Subject()
    equal(tracker.eventType, K.EVT_QUESTION_VIEWED)
    equal(tracker.priority, K.EVT_PRIORITY_LOW)
  })

  // fails in Jest, passes in QUnit
  // :in_viewport doesn't work in Jest
  test.skip('#identifyVisibleQuestions', () => {
    const tracker = new Subject()
    createQuestion('123')
    equal(
      JSON.stringify(tracker.identifyVisibleQuestions()),
      JSON.stringify(['123']),
      'it identifies currently visible questions'
    )
  })

  test.skip('capturing: it works', () => {
    const tracker = new Subject({frequency: 0})
    const capture = sinon.stub()
    tracker.install(capture, scrollSelector)
    const offsetTop = 3500
    const $fakeQuestion = createQuestion('123')
    $fakeQuestion.css({
      height: '1px', // needs some height to be considered visible
      'margin-top': offsetTop,
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
})

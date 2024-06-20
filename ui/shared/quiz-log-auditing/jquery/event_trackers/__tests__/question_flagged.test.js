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

import $ from 'jquery'
import Subject from '../question_flagged'
import K from '../../constants'
import sinon from 'sinon'

const ok = value => expect(value).toBeTruthy()
const equal = (value, expected) => expect(value).toEqual(expected)

let $question

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const createQuestion = function (id) {
  $question = $('<div />', {
    class: 'question',
    id: `question_${id}`,
  }).appendTo(document.getElementById('fixtures'))
  $('<a />', {class: 'flag_question'})
    .appendTo($question)
    .on('click', () => $question.toggleClass('marked'))
  return $question
}

describe('Quizzes::LogAuditing::EventTrackers::QuestionFlagged', () => {
  beforeEach(() => {})

  afterEach(() => {
    document.getElementById('fixtures').innerHTML = ''

    if ($question) {
      $question.remove()
    }
  })

  test('#constructor: it sets up the proper context', () => {
    const tracker = new Subject()
    equal(tracker.eventType, K.EVT_QUESTION_FLAGGED)
    equal(tracker.priority, K.EVT_PRIORITY_LOW)
  })

  test('capturing: it works', () => {
    const capture = sinon.stub()
    const tracker = new Subject({
      questionSelector: '.question',
      questionMarkedClass: 'marked',
      buttonSelector: '.flag_question',
    })
    tracker.install(capture)
    const $fakeQuestion = createQuestion('123')
    $fakeQuestion.find('a.flag_question').click()
    ok(
      capture.calledWith({
        questionId: '123',
        flagged: true,
      })
    )
    $fakeQuestion.find('a.flag_question').click()
    ok(
      capture.calledWith({
        questionId: '123',
        flagged: false,
      })
    )
  })
})

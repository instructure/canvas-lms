/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

/* eslint-disable import/no-dynamic-require */

import $ from 'jquery'
import 'jquery-migrate'

/* NOTE: this test is meant to test 'quizzes', but you'll notice that the define
   does not include the 'quizzes' module. this is because simply including the
   quizzes module breaks the KeyboardShortcutsSpec.js spec test later. there is
   a side effect from including 'quizzes' when the $document.ready() method is
   called. a line in there calls the render() of RCEKeyboardShortcut which
   creates a side effect to fail a later test. so what we do here is stub out
   the ready() $.fn , then restore it after we are done
   to avoid the side-effect. see CNVS-30988.
*/

const $questionContent = {bind() {}}

QUnit.module('isChangeMultiFuncBound', {
  setup() {
    sandbox.stub($, '_data')
  },
})

test('gets events from data on first element', assert => {
  const done = assert.async()
  const $el = [{}]
  require(['ui/features/quizzes/jquery/quizzes'], ({isChangeMultiFuncBound}) => {
    isChangeMultiFuncBound($el)
    ok($._data.calledWithExactly($el[0], 'events'))
    done()
  })
})

test('returns true if el has correct change event', assert => {
  const done = assert.async()
  const $el = [{}]
  const events = {
    change: [{handler: {origFuncNm: 'changeMultiFunc'}}],
  }
  require(['ui/features/quizzes/jquery/quizzes'], ({isChangeMultiFuncBound}) => {
    $._data.returns(events)
    ok(isChangeMultiFuncBound($el))
    done()
  })
})

test('returns false if el has incorrect change event', assert => {
  const done = assert.async()
  const $el = [{}]
  const events = {
    change: [{handler: {name: 'other'}}],
  }
  require(['ui/features/quizzes/jquery/quizzes'], ({isChangeMultiFuncBound}) => {
    $._data.returns(events)
    ok(!isChangeMultiFuncBound($el))
    done()
  })
})

QUnit.module('rebindMultiChange', {
  setup() {
    sandbox.stub($questionContent, 'bind')
    sandbox.stub($, '_data')
    $questionContent.bind.returns({change() {}})
  },
})

test('rebinds event on questionContent', assert => {
  const done = assert.async()
  const questionType = 'multiple_dropdowns_question'
  const events = {
    change: [{handler: {name: 'other'}}],
  }
  $._data.returns(events)
  require(['ui/features/quizzes/jquery/quizzes'], ({quiz}) => {
    sandbox.stub(quiz, 'loadJQueryElemById')
    quiz.loadJQueryElemById.returns($questionContent)
    quiz.rebindMultiChange(questionType, 'question_content_0', {})
    equal($questionContent.bind.callCount, 1)
    done()
  })
})

test('does nothing if "change" event exists', assert => {
  const done = assert.async()
  const questionType = 'multiple_dropdowns_question'
  const events = {
    change: [{handler: {origFuncNm: 'changeMultiFunc'}}],
  }
  $._data.returns(events)
  require(['ui/features/quizzes/jquery/quizzes'], ({quiz}) => {
    sandbox.stub(quiz, 'loadJQueryElemById')
    quiz.loadJQueryElemById.returns($questionContent)
    quiz.rebindMultiChange(questionType, 'question_content_0', {})
    equal($questionContent.bind.callCount, 0)
    done()
  })
})

test('does nothing if wrong questionType', assert => {
  const done = assert.async()
  const questionType = 'other_question'
  const events = {
    change: [{handler: {name: 'other'}}],
  }
  $._data.returns(events)
  require(['ui/features/quizzes/jquery/quizzes'], ({quiz}) => {
    sandbox.stub(quiz, 'loadJQueryElemById')
    quiz.loadJQueryElemById.returns($questionContent)
    quiz.rebindMultiChange(questionType, 'question_content_0', {})
    equal($questionContent.bind.callCount, 0)
    done()
  })
})

/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock ready to prevent blocking on DOM ready during module import
vi.mock('@instructure/ready', () => ({
  default: vi.fn(),
}))

const $questionContent = {
  bind: vi.fn().mockReturnValue({change: vi.fn()}),
}

describe('rebindMultiChange', () => {
  let quiz

  beforeEach(async () => {
    fakeENV.setup()
    $._data = vi.fn()
    const module = await import('../quizzes')
    quiz = module.quiz
    quiz.loadJQueryElemById = vi.fn().mockReturnValue($questionContent)
  })

  afterEach(() => {
    vi.clearAllMocks()
    fakeENV.teardown()
  })

  it('rebinds event on questionContent for multiple dropdowns', () => {
    const questionType = 'multiple_dropdowns_question'
    const events = {
      change: [{handler: {name: 'other'}}],
    }
    $._data.mockReturnValue(events)

    quiz.rebindMultiChange(questionType, 'question_content_0', {})

    expect($questionContent.bind).toHaveBeenCalledTimes(1)
  })

  it('does nothing if change event already exists', () => {
    const questionType = 'multiple_dropdowns_question'
    const events = {
      change: [{handler: {origFuncNm: 'changeMultiFunc'}}],
    }
    $._data.mockReturnValue(events)

    quiz.rebindMultiChange(questionType, 'question_content_0', {})

    expect($questionContent.bind).not.toHaveBeenCalled()
  })

  it('does nothing for non-multiple dropdown question types', () => {
    const questionType = 'other_question'
    const events = {
      change: [{handler: {name: 'other'}}],
    }
    $._data.mockReturnValue(events)

    quiz.rebindMultiChange(questionType, 'question_content_0', {})

    expect($questionContent.bind).not.toHaveBeenCalled()
  })
})

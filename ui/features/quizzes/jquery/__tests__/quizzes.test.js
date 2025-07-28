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
 * with this program. If not, see &lt;http://www.gnu.org/licenses/&gt;.
 */

import $ from 'jquery'
import 'jquery-migrate'

const $questionContent = {
  bind: jest.fn().mockReturnValue({change: jest.fn()}),
}

describe('isChangeMultiFuncBound', () => {
  let isChangeMultiFuncBound

  beforeEach(async () => {
    $._data = jest.fn()
    const module = await import('../quizzes')
    isChangeMultiFuncBound = module.isChangeMultiFuncBound
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('gets events from data on first element', () => {
    const $el = [{}]
    isChangeMultiFuncBound($el)
    expect($._data).toHaveBeenCalledWith($el[0], 'events')
  })

  it('returns true if element has correct change event', () => {
    const $el = [{}]
    const events = {
      change: [{handler: {origFuncNm: 'changeMultiFunc'}}],
    }
    $._data.mockReturnValue(events)
    expect(isChangeMultiFuncBound($el)).toBe(true)
  })

  it('returns false if element has incorrect change event', () => {
    const $el = [{}]
    const events = {
      change: [{handler: {name: 'other'}}],
    }
    $._data.mockReturnValue(events)
    expect(isChangeMultiFuncBound($el)).toBe(false)
  })
})

describe('rebindMultiChange', () => {
  let quiz

  beforeEach(async () => {
    $._data = jest.fn()
    const module = await import('../quizzes')
    quiz = module.quiz
    quiz.loadJQueryElemById = jest.fn().mockReturnValue($questionContent)
  })

  afterEach(() => {
    jest.clearAllMocks()
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

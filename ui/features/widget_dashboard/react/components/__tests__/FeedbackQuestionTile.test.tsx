/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React from 'react'
import {cleanup, render, screen} from '@testing-library/react'
import FeedbackQuestionTile from '../FeedbackQuestionTile'

describe('FeedbackQuestionTile', () => {
  beforeEach(() => {
    sessionStorage.clear()
  })

  afterEach(() => {
    cleanup()
    sessionStorage.clear()
  })

  it('renders a feedback question', () => {
    render(<FeedbackQuestionTile />)
    const tile = screen.getByTestId('feedback-question-tile')
    expect(tile).toBeInTheDocument()
  })

  it('renders one of the three possible questions', () => {
    render(<FeedbackQuestionTile />)

    const possibleQuestions = [
      'What do you think of the new dashboard?',
      'Have an idea for a new widget?',
      'What would make this dashboard better?',
    ]

    const hasQuestion = possibleQuestions.some(question => {
      return screen.queryByText(question) !== null
    })

    expect(hasQuestion).toBe(true)
  })

  it('renders a feedback link', () => {
    render(<FeedbackQuestionTile />)

    const possibleLinkTexts = ['Let us know!', 'Please share your feedback!']

    const hasLink = possibleLinkTexts.some(linkText => {
      return screen.queryByText(linkText) !== null
    })

    expect(hasLink).toBe(true)
  })

  it('link opens in a new tab', () => {
    render(<FeedbackQuestionTile />)

    const link = screen.getByTestId('feedback-question-link')
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('link points to the correct feedback form', () => {
    render(<FeedbackQuestionTile />)

    const link = screen.getByTestId('feedback-question-link')
    expect(link).toHaveAttribute(
      'href',
      'https://docs.google.com/forms/d/e/1FAIpQLSfy8bDc50ay-KfdBZmt-SwP7yKOHIjNaVobHMOwFHDzfB7OXw/viewform?usp=header',
    )
  })

  it('starts with the first question when no session data exists', () => {
    render(<FeedbackQuestionTile />)
    expect(screen.getByText('What do you think of the new dashboard?')).toBeInTheDocument()
  })

  it('cycles to the next question on each page visit', () => {
    sessionStorage.clear()

    render(<FeedbackQuestionTile />)
    expect(screen.getByText('What do you think of the new dashboard?')).toBeInTheDocument()
    expect(sessionStorage.getItem('feedback_question_index')).toBe('0')

    sessionStorage.clear()
    sessionStorage.setItem('feedback_question_index', '0')
    render(<FeedbackQuestionTile />)
    expect(screen.getByText('Have an idea for a new widget?')).toBeInTheDocument()

    sessionStorage.clear()
    sessionStorage.setItem('feedback_question_index', '1')
    render(<FeedbackQuestionTile />)
    expect(screen.getByText('What would make this dashboard better?')).toBeInTheDocument()
  })

  it('wraps back to the first question after the last one', () => {
    sessionStorage.setItem('feedback_question_index', '2')
    render(<FeedbackQuestionTile />)
    expect(screen.getByText('What do you think of the new dashboard?')).toBeInTheDocument()
  })
})
